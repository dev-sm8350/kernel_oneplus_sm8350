/*
 * okcar.c
 *
 * Copyright (C) Okcar
 * Contact: Leo <leo@okcaros.com>
 *
 * Okcar Kernel Api
 * How to use?
 *  echo "command,param_type,param\n" > /dev/okcar
 *  echo "usbmode,1,1\n" > /dev/okcar               // Toggle usb mode to Device
 *  echo "usbmode,1,2\n" > /dev/okcar               // Toggle usb mode to Host
 * param_type 1: int, 2: string
 */

#include <linux/module.h>
#include <linux/fs.h>
#include <linux/cdev.h>
#include <linux/device.h>
#include <linux/uaccess.h>
#include <linux/string.h>
#include <linux/slab.h>

// enum OKCAR_USB_MODE {
// 	unknow = -1,
//     none = 0,
//     device = 1,
//     host = 2
// };
extern int okcar_usbmode_get(void);
extern void okcar_usbmode_toggle(int mode);

#define DEVICE_NAME "okcar"
#define BUF_SIZE 1024

static dev_t dev;
static struct cdev cdev;
static struct class *device_class;
static char buffer[BUF_SIZE];

static int device_open(struct inode *inode, struct file *file)
{
    printk(KERN_INFO "Device opened\n");
    return 0;
}

static int device_release(struct inode *inode, struct file *file)
{
    printk(KERN_INFO "Device closed\n");
    return 0;
}

static ssize_t device_read(struct file *file, char __user *user_buf, size_t count, loff_t *offset)
{
    int len;
    if (*offset >= BUF_SIZE)
        return 0;

    if (*offset == 0) {
        int mode = okcar_usbmode_get();
        len = sizeof(int);
        copy_to_user(user_buf, &mode, len);
    } else {
        len = 0;
    }
    
    *offset += len;
    return len;
}

static ssize_t device_write(struct file *file, const char __user *user_buf, size_t count, loff_t *offset)
{
    int len;
    char commands[BUF_SIZE];
    char *line = NULL;
    char *command = NULL;
    char *command_copy = NULL;
    char *param_type = NULL;
    char *param = NULL;
    
    if (*offset >= BUF_SIZE)
        return 0;
    len = min(count, (size_t)(BUF_SIZE - *offset));
    if (copy_from_user(buffer + *offset, user_buf, len) != 0)
        return -EFAULT;
    *offset += len;
    buffer[*offset] = '\0';

    strcpy(commands, buffer);

    // Process each command
    line = commands;
    while ((command = strsep(&line, "\n")) != NULL) {
        if (*command == '\0') {
            continue;  // Ignore empty lines
        }

        // Process command and parameter
        command_copy = kstrndup(command, strlen(command), GFP_KERNEL);
        if (!command_copy) {
            printk(KERN_ALERT "Failed to allocate memory for command copy\n");
            return -ENOMEM;
        }
        command = strsep(&command_copy, ",");
        param_type = strsep(&command_copy, ",");
        param = strsep(&command_copy, ",");
        
        if (command && param_type && param) {
            int type;
            int intParam;

            if (kstrtoint(param_type, 10, &type) != 0) {
                printk(KERN_INFO "Invalid param type input: %s\n", param_type);
                kfree(command_copy);
                continue;
            }

            if (strcmp(command, "usbmode") == 0) {
                if (type != 1) {
                    printk(KERN_ALERT "[usbmode] Invalid integer param");
                    continue;
                }
                if (kstrtoint(param, 10, &intParam) != 0) {
                    printk(KERN_INFO "[usbmode] Invalid integer param: %s\n", param);
                    kfree(command_copy);
                    continue;
                }
                printk(KERN_INFO "[usbmode] newMode: %d\n", intParam);
                okcar_usbmode_toggle(intParam);
            }
        }
        kfree(command_copy);
    }

    return len;
}

static struct file_operations fops = {
    .open = device_open,
    .release = device_release,
    .read = device_read,
    .write = device_write,
};

static int __init okcar_init(void)
{
    if (alloc_chrdev_region(&dev, 0, 1, DEVICE_NAME) < 0) {
        printk(KERN_ALERT "Failed to allocate device number\n");
        return -1;
    }

    cdev_init(&cdev, &fops);
    if (cdev_add(&cdev, dev, 1) == -1) {
        printk(KERN_ALERT "Failed to add character device\n");
        unregister_chrdev_region(dev, 1);
        return -1;
    }

    device_class = class_create(THIS_MODULE, DEVICE_NAME);
    if (device_class == NULL) {
        printk(KERN_ALERT "Failed to create device class\n");
        cdev_del(&cdev);
        unregister_chrdev_region(dev, 1);
        return -1;
    }

    if (device_create(device_class, NULL, dev, NULL, DEVICE_NAME) == NULL) {
        printk(KERN_ALERT "Failed to create device\n");
        class_destroy(device_class);
        cdev_del(&cdev);
        unregister_chrdev_region(dev, 1);
        return -1;
    }

    printk(KERN_INFO "Device driver loaded\n");
    return 0;
}

static void __exit okcar_exit(void)
{
    device_destroy(device_class, dev);
    class_destroy(device_class);
    cdev_del(&cdev);
    unregister_chrdev_region(dev, 1);
    printk(KERN_INFO "Device driver unloaded\n");
}

module_init(okcar_init);
module_exit(okcar_exit);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Leo");
MODULE_DESCRIPTION("Okcar Kernel Api");

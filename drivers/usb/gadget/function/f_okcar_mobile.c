/*
 * Gadget Function Driver for Android USB accessories
 *
 * Copyright (C) 2011 Google, Inc.
 * Author: Mike Lockwood <lockwood@android.com>
 *
 * This software is licensed under the terms of the GNU General Public
 * License version 2, as published by the Free Software Foundation, and
 * may be copied, distributed, and modified under those terms.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 */

/* #define DEBUG */
/* #define VERBOSE_DEBUG */

#include <linux/module.h>
#include <linux/init.h>
#include <linux/poll.h>
#include <linux/delay.h>
#include <linux/wait.h>
#include <linux/err.h>
#include <linux/interrupt.h>
#include <linux/kthread.h>
#include <linux/freezer.h>

#include <linux/types.h>
#include <linux/file.h>
#include <linux/device.h>

#include <linux/usb.h>
#include <linux/usb/ch9.h>
#include <linux/usb/f_accessory.h>

#include <linux/configfs.h>
#include <linux/usb/composite.h>

#define MAX_INST_NAME_LEN        40
#define BULK_BUFFER_SIZE    16384
#define ACC_STRING_SIZE     256

#define PROTOCOL_VERSION    2

/* String IDs */
#define INTERFACE_STRING_INDEX	0

/* number of tx and rx requests to allocate */
#define TX_REQ_MAX 4
#define RX_REQ_MAX 2

struct acc_dev {
	struct usb_function function;
	struct usb_composite_dev *cdev;
	spinlock_t lock;

	struct usb_ep *ep_in;
	struct usb_ep *ep_out;

	struct list_head tx_idle;
	struct usb_request *rx_req[RX_REQ_MAX];

	struct usb_interface_descriptor acc_interface_desc;
	struct usb_endpoint_descriptor acc_highspeed_in_desc;
	struct usb_endpoint_descriptor acc_highspeed_out_desc;
	struct usb_endpoint_descriptor acc_fullspeed_in_desc;
	struct usb_endpoint_descriptor acc_fullspeed_out_desc;
	struct usb_descriptor_header *fs_acc_descs[4];
	struct usb_descriptor_header *hs_acc_descs[4];
	struct usb_string acc_string_defs[2];
	struct usb_gadget_strings acc_string_table;
	struct usb_gadget_strings *acc_strings[2];

	struct configfs_item_operations acc_item_ops;
	struct config_item_type acc_func_type;
};

struct acc_instance {
	struct usb_function_instance func_inst;
	const char *name;
	struct acc_dev *_acc_dev;
};

static inline struct acc_dev *func_to_dev(struct usb_function *f)
{
	return container_of(f, struct acc_dev, function);
}

static inline struct acc_instance *to_fi_acc(struct usb_function_instance *fi)
{
	return container_of(fi, struct acc_instance, func_inst);
}

static struct usb_request *acc_request_new(struct usb_ep *ep, int buffer_size)
{
	struct usb_request *req = usb_ep_alloc_request(ep, GFP_KERNEL);

	if (!req)
		return NULL;

	/* now allocate buffers for the requests */
#if defined(CONFIG_64BIT) && defined(CONFIG_MTK_LM_MODE)
	req->buf = kmalloc(buffer_size, GFP_KERNEL | GFP_DMA);
#else
	req->buf = kmalloc(buffer_size, GFP_KERNEL);
#endif
	if (!req->buf) {
		usb_ep_free_request(ep, req);
		return NULL;
	}

	return req;
}

static void acc_request_free(struct usb_request *req, struct usb_ep *ep)
{
	if (req) {
		kfree(req->buf);
		usb_ep_free_request(ep, req);
	}
}

/* add a request to the tail of a list */
static void req_put(struct acc_dev *dev, struct list_head *head,
		struct usb_request *req)
{
	unsigned long flags;

	spin_lock_irqsave(&dev->lock, flags);
	list_add_tail(&req->list, head);
	spin_unlock_irqrestore(&dev->lock, flags);
}

/* remove a request from the head of a list */
static struct usb_request *req_get(struct acc_dev *dev, struct list_head *head)
{
	unsigned long flags;
	struct usb_request *req;

	spin_lock_irqsave(&dev->lock, flags);
	if (list_empty(head)) {
		req = 0;
	} else {
		req = list_first_entry(head, struct usb_request, list);
		list_del(&req->list);
	}
	spin_unlock_irqrestore(&dev->lock, flags);
	return req;
}

static void acc_complete_in(struct usb_ep *ep, struct usb_request *req)
{
	struct acc_dev *dev = ep->driver_data;

	req_put(dev, &dev->tx_idle, req);
}

static void acc_complete_out(struct usb_ep *ep, struct usb_request *req)
{

}

// static void acc_complete_setup_noop(struct usb_ep *ep, struct usb_request *req)
// {
// 	/*
// 	 * Default no-op function when nothing needs to be done for the
// 	 * setup request
// 	 */
// }

static int create_bulk_endpoints(struct acc_dev *dev,
				struct usb_endpoint_descriptor *in_desc,
				struct usb_endpoint_descriptor *out_desc)
{
	struct usb_composite_dev *cdev = dev->cdev;
	struct usb_request *req;
	struct usb_ep *ep;
	int i;

	DBG(cdev, "create_bulk_endpoints dev: %p\n", dev);

	ep = usb_ep_autoconfig(cdev->gadget, in_desc);
	if (!ep) {
		DBG(cdev, "usb_ep_autoconfig for ep_in failed\n");
		return -ENODEV;
	}
	DBG(cdev, "usb_ep_autoconfig for ep_in got %s\n", ep->name);
	ep->driver_data = dev;		/* claim the endpoint */
	dev->ep_in = ep;

	ep = usb_ep_autoconfig(cdev->gadget, out_desc);
	if (!ep) {
		DBG(cdev, "usb_ep_autoconfig for ep_out failed\n");
		return -ENODEV;
	}
	DBG(cdev, "usb_ep_autoconfig for ep_out got %s\n", ep->name);
	ep->driver_data = dev;		/* claim the endpoint */
	dev->ep_out = ep;

	/* now allocate requests for our endpoints */
	for (i = 0; i < TX_REQ_MAX; i++) {
		req = acc_request_new(dev->ep_in, BULK_BUFFER_SIZE);
		if (!req)
			goto fail;
		req->complete = acc_complete_in;
		req_put(dev, &dev->tx_idle, req);
	}
	for (i = 0; i < RX_REQ_MAX; i++) {
		req = acc_request_new(dev->ep_out, BULK_BUFFER_SIZE);
		if (!req)
			goto fail;
		req->complete = acc_complete_out;
		dev->rx_req[i] = req;
	}

	return 0;

fail:
	pr_err("acc_bind() could not allocate requests\n");
	while ((req = req_get(dev, &dev->tx_idle)))
		acc_request_free(req, dev->ep_in);
	for (i = 0; i < RX_REQ_MAX; i++)
		acc_request_free(dev->rx_req[i], dev->ep_out);
	return -1;
}

static int
__acc_function_bind(struct usb_configuration *c,
			struct usb_function *f, bool configfs)
{
	struct usb_composite_dev *cdev = c->cdev;
	struct acc_dev	*dev = func_to_dev(f);
	int			id;
	int			ret;

	DBG(cdev, "acc_function_bind dev: %p\n", dev);

	if (configfs) {
		// if (dev->acc_string_defs[INTERFACE_STRING_INDEX].id == 0) {
		// 	ret = usb_string_id(c->cdev);
		// 	if (ret < 0)
		// 		return ret;
		// 	dev->acc_string_defs[INTERFACE_STRING_INDEX].id = ret;
		// 	dev->acc_interface_desc.iInterface = ret;
		// }
		dev->acc_string_defs[INTERFACE_STRING_INDEX].id = 12;
		dev->acc_interface_desc.iInterface = 12;
		dev->cdev = c->cdev;
	}

	/* allocate interface ID(s) */
	id = usb_interface_id(c, f);
	if (id < 0)
		return id;
	dev->acc_interface_desc.bInterfaceNumber = id;

	/* allocate endpoints */
	ret = create_bulk_endpoints(dev, &(dev->acc_fullspeed_in_desc),
			&(dev->acc_fullspeed_out_desc));
	if (ret)
		return ret;

	/* support high speed hardware */
	if (gadget_is_dualspeed(c->cdev->gadget)) {
		dev->acc_highspeed_in_desc.bEndpointAddress =
			dev->acc_fullspeed_in_desc.bEndpointAddress;
		dev->acc_highspeed_out_desc.bEndpointAddress =
			dev->acc_fullspeed_out_desc.bEndpointAddress;
	}

	DBG(cdev, "%s speed %s: IN/%s, OUT/%s\n",
			gadget_is_dualspeed(c->cdev->gadget) ? "dual" : "full",
			f->name, dev->ep_in->name, dev->ep_out->name);
	return 0;
}

static int
acc_function_bind_configfs(struct usb_configuration *c,
			struct usb_function *f) {
	return __acc_function_bind(c, f, true);
}


static void
acc_function_unbind(struct usb_configuration *c, struct usb_function *f)
{
	struct acc_dev	*dev = func_to_dev(f);
	struct usb_request *req;
	int i;

	while ((req = req_get(dev, &dev->tx_idle)))
		acc_request_free(req, dev->ep_in);
	for (i = 0; i < RX_REQ_MAX; i++)
		acc_request_free(dev->rx_req[i], dev->ep_out);
}

static int acc_function_set_alt(struct usb_function *f,
		unsigned intf, unsigned alt)
{
	struct acc_dev	*dev = func_to_dev(f);
	struct usb_composite_dev *cdev = f->config->cdev;
	int ret;

	DBG(cdev, "acc_function_set_alt intf: %d alt: %d\n", intf, alt);

	ret = config_ep_by_speed(cdev->gadget, f, dev->ep_in);
	if (ret)
		return ret;

	ret = usb_ep_enable(dev->ep_in);
	if (ret)
		return ret;

	ret = config_ep_by_speed(cdev->gadget, f, dev->ep_out);
	if (ret)
		return ret;

	ret = usb_ep_enable(dev->ep_out);
	if (ret) {
		usb_ep_disable(dev->ep_in);
		return ret;
	}

	return 0;
}

static void acc_function_disable(struct usb_function *f)
{
	struct acc_dev	*dev = func_to_dev(f);
	struct usb_composite_dev	*cdev = dev->cdev;

	DBG(cdev, "acc_function_disable\n");
	usb_ep_disable(dev->ep_in);
	usb_ep_disable(dev->ep_out);

	VDBG(cdev, "%s disabled\n", dev->function.name);
}

static void acc_free(struct usb_function *f)
{
/*NO-OP: no function specific resource allocation in mtp_alloc*/
}

static int acc_ctrlrequest(struct usb_composite_dev *cdev,
				const struct usb_ctrlrequest *ctrl, struct acc_dev	*dev)
{
	int	value = -EOPNOTSUPP;
	return value;
}

static int acc_ctrlrequest_configfs(struct usb_function *f,
			const struct usb_ctrlrequest *ctrl) {
	struct acc_dev	*dev = func_to_dev(f);
	if (f->config != NULL && f->config->cdev != NULL)
		return acc_ctrlrequest(f->config->cdev, ctrl, dev);
	else
		return -1;
}

static struct usb_function *acc_alloc(struct usb_function_instance *fi)
{
	struct acc_dev *dev; 
	
	dev = to_fi_acc(fi)->_acc_dev;
	dev->function.name = "okcar_mobile";
	dev->function.strings = dev->acc_strings,
	dev->function.fs_descriptors = dev->fs_acc_descs;
	dev->function.hs_descriptors = dev->hs_acc_descs;
	dev->function.bind = acc_function_bind_configfs;
	dev->function.unbind = acc_function_unbind;
	dev->function.set_alt = acc_function_set_alt;
	dev->function.disable = acc_function_disable;
	dev->function.free_func = acc_free;
	dev->function.setup = acc_ctrlrequest_configfs;

	return &dev->function;
}

static struct acc_instance *to_acc_instance(struct config_item *item)
{
	return container_of(to_config_group(item), struct acc_instance,
		func_inst.group);
}
static void acc_attr_release(struct config_item *item)
{
	struct acc_instance *fi_acc = to_acc_instance(item);

	usb_put_function_instance(&fi_acc->func_inst);
}

static int acc_set_inst_name(struct usb_function_instance *fi, const char *name)
{
	struct acc_instance *fi_acc;
	char *ptr;
	int name_len;

	name_len = strlen(name) + 1;
	if (name_len > MAX_INST_NAME_LEN)
		return -ENAMETOOLONG;

	ptr = kstrndup(name, name_len, GFP_KERNEL);
	if (!ptr)
		return -ENOMEM;

	fi_acc = to_fi_acc(fi);
	fi_acc->name = ptr;
	return 0;
}

static void acc_free_inst(struct usb_function_instance *fi)
{
	struct acc_instance *fi_acc;

	fi_acc = to_fi_acc(fi);
	kfree(fi_acc->name);
	kfree(fi_acc->_acc_dev);
	fi_acc->_acc_dev = NULL;
	kfree(fi_acc);
}

static struct usb_function_instance *acc_alloc_inst(void)
{
	struct acc_instance *fi_acc;
	struct acc_dev *dev;

	fi_acc = kzalloc(sizeof(*fi_acc), GFP_KERNEL);
	if (!fi_acc)
		goto err1;
	fi_acc->func_inst.set_inst_name = acc_set_inst_name;
	fi_acc->func_inst.free_func_inst = acc_free_inst;

	dev = kzalloc(sizeof(*dev), GFP_KERNEL);
	if (!dev)
		goto err2;
	
	fi_acc->_acc_dev = dev;
	spin_lock_init(&dev->lock);
	INIT_LIST_HEAD(&dev->tx_idle);

	dev->acc_interface_desc.bLength					= USB_DT_INTERFACE_SIZE;
	dev->acc_interface_desc.bDescriptorType			= USB_DT_INTERFACE;
	dev->acc_interface_desc.bInterfaceNumber		= 0;
	dev->acc_interface_desc.bNumEndpoints			= 2;
	dev->acc_interface_desc.bInterfaceClass			= USB_CLASS_VENDOR_SPEC;
	dev->acc_interface_desc.bInterfaceSubClass		= 254;
	dev->acc_interface_desc.bInterfaceProtocol		= 2;

	dev->acc_highspeed_in_desc.bLength				= USB_DT_ENDPOINT_SIZE;
	dev->acc_highspeed_in_desc.bDescriptorType		= USB_DT_ENDPOINT;
	dev->acc_highspeed_in_desc.bEndpointAddress		= USB_DIR_IN;
	dev->acc_highspeed_in_desc.bmAttributes			= USB_ENDPOINT_XFER_BULK;
	dev->acc_highspeed_in_desc.wMaxPacketSize		= __constant_cpu_to_le16(512);

	dev->acc_highspeed_out_desc.bLength				= USB_DT_ENDPOINT_SIZE;
	dev->acc_highspeed_out_desc.bDescriptorType		= USB_DT_ENDPOINT;
	dev->acc_highspeed_out_desc.bEndpointAddress	= USB_DIR_OUT;
	dev->acc_highspeed_out_desc.bmAttributes		= USB_ENDPOINT_XFER_BULK;
	dev->acc_highspeed_out_desc.wMaxPacketSize		= __constant_cpu_to_le16(512);

	dev->acc_fullspeed_in_desc.bLength				= USB_DT_ENDPOINT_SIZE;
	dev->acc_fullspeed_in_desc.bDescriptorType		= USB_DT_ENDPOINT;
	dev->acc_fullspeed_in_desc.bEndpointAddress		= USB_DIR_IN;
	dev->acc_fullspeed_in_desc.bmAttributes			= USB_ENDPOINT_XFER_BULK;

	dev->acc_fullspeed_out_desc.bLength				= USB_DT_ENDPOINT_SIZE;
	dev->acc_fullspeed_out_desc.bDescriptorType		= USB_DT_ENDPOINT;
	dev->acc_fullspeed_out_desc.bEndpointAddress	= USB_DIR_OUT;
	dev->acc_fullspeed_out_desc.bmAttributes		= USB_ENDPOINT_XFER_BULK;

	dev->fs_acc_descs[0] = (struct usb_descriptor_header *) &(dev->acc_interface_desc);
	dev->fs_acc_descs[1] = (struct usb_descriptor_header *) &(dev->acc_fullspeed_out_desc);
	dev->fs_acc_descs[2] = (struct usb_descriptor_header *) &(dev->acc_fullspeed_in_desc);
	dev->fs_acc_descs[3] = NULL;

	dev->hs_acc_descs[0] = (struct usb_descriptor_header *) &(dev->acc_interface_desc);
	dev->hs_acc_descs[1] = (struct usb_descriptor_header *) &(dev->acc_highspeed_out_desc);
	dev->hs_acc_descs[2] = (struct usb_descriptor_header *) &(dev->acc_highspeed_in_desc);
	dev->hs_acc_descs[3] = NULL;

	dev->acc_string_defs[INTERFACE_STRING_INDEX].s  = "Apple USB Multiplexor";
	dev->acc_string_defs[INTERFACE_STRING_INDEX].id = 0;

	dev->acc_string_table.language		= 0x0409;	/* en-US */
	dev->acc_string_table.strings		= dev->acc_string_defs;

	dev->acc_strings[0] = &(dev->acc_string_table);
	dev->acc_strings[1] = NULL;

	dev->acc_item_ops.release		= acc_attr_release;

	dev->acc_func_type.ct_item_ops	= &(dev->acc_item_ops);
	dev->acc_func_type.ct_owner		= THIS_MODULE;

	config_group_init_type_name(&fi_acc->func_inst.group,
					"", &(dev->acc_func_type));

	return  &fi_acc->func_inst;

err2:
	kfree(fi_acc);
	pr_err("Error setting acc_dev\n");
err1:
	pr_err("Error setting acc_instance\n");
	return ERR_PTR(-ENOMEM);
}

DECLARE_USB_FUNCTION_INIT(okcar_mobile, acc_alloc_inst, acc_alloc);
MODULE_LICENSE("GPL");

//
//  USBHeaders.h
//  CameraController
//
//  Created by Itay Brenner on 7/20/20.
//  Copyright © 2020 Itaysoft. All rights reserved.
//

#include <stdint.h>

struct UVC_InterfaceDescriptorHdr {
    uint8_t bLength;
    uint8_t bDescriptorType;
    uint8_t bDescriptorSubType;
} __attribute__((packed));

struct UVC_VCHeaderDescriptor {
    uint8_t  bLength;
    uint8_t  bDescriptorType;
    uint8_t  bDescriptorSubType;
    uint16_t bcdUVC;
    uint16_t wTotalLength;
    uint32_t dwClockFrequency;
    uint8_t  bInCollection;
    uint8_t  baInterface;    /* TODO: array, but we're not using this. */
} __attribute__((packed));

struct UVC_CameraTerminalDescriptor {
    uint8_t  bLength;
    uint8_t  bDescriptorType;
    uint8_t  bDescriptorSubType;
    uint8_t  bTerminalID;
    uint16_t wTerminalType;
    uint8_t  bAssocTerminal;
    uint8_t  iTerminal;
    uint16_t wObjectiveFocalLengthMin;
    uint16_t wObjectiveFocalLengthMax;
    uint16_t wOcularFocalLength;
    uint8_t  bControlSize;
    uint8_t  bmControls;    /* TODO: array, but we're not using this (yet). */
} __attribute__((packed));

struct UVC_ProcessingUnitDescriptor {
    uint8_t  bLength;
    uint8_t  bDescriptorType;
    uint8_t  bDescriptorSubType;
    uint8_t  bUnitID;
    uint8_t  bSourceID;
    uint16_t wMaxMultiplier;
    uint8_t  bControlSize;
    uint8_t  bmControls;    /* TODO: array, but we're not using this (yet). */
    /* TODO: iProcessing and bmVideoStandards */
} __attribute__((packed));

/*
 * Class-Specific VC Extension Unit Descriptor (UVC 1.5 spec, section 3.7.2.6).
 * The trailing fields are variable-length; this struct only covers the fixed
 * prefix up to and including guidExtensionCode and bNumControls. The remaining
 * fields (baSourceID[bNrInPins], bControlSize, bmControls[bControlSize],
 * bIExtension) must be parsed by walking from a byte pointer.
 */
struct UVC_ExtensionUnitDescriptor {
    uint8_t  bLength;
    uint8_t  bDescriptorType;
    uint8_t  bDescriptorSubType;
    uint8_t  bUnitID;
    uint8_t  guidExtensionCode[16];
    uint8_t  bNumControls;
    uint8_t  bNrInPins;
    /* Variable tail follows: baSourceID[bNrInPins], bControlSize,
     * bmControls[bControlSize], bIExtension. */
} __attribute__((packed));

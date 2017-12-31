/*
 *  hidutil.c
 *  Keytar MIDI Connector
 *
 *  Created by Gregory Keeney on 1/2/11.
 *  Copyright 2011 __MyCompanyName__. All rights reserved.
 *
 */

#include "hidutil.h"
#include "midiutil.h"
#include "stdio.h"

#import <IOKit/hid/IOHIDLib.h>
#import <IOKit/hid/IOHIDBase.h>
#import <IOKit/hid/IOHIDKeys.h>

IOHIDManagerRef hidmanager;
IOHIDDeviceRef deviceRef;

// XXX - need to set up USB connection / disconnection detection


// Cookie 0x23 Event count of some kind

#define LOWREG_COOKIE 0x12 // Cookie 0x12 C3-G3
#define MIDREG_COOKIE 0x13 // Cookie 0x13 G#3-D#4
#define HIGHREG_COOKIE 0x14 // Cookie 0x14 E4-B5
#define VELOCITY_COOKIE 0x15 // Cookie 0x15 Velocity & C5

#define BUTTON_1_COOKIE 0x02 // Cookie for Button 1 (down octave)
#define BUTTON_2_COOKIE 0x05 // Cookie for Button 2 (Not Yet Implemented)
#define BUTTON_A_COOKIE 0x03 // Cookie for Button A (Not Yet Implemented)
#define BUTTON_B_COOKIE 0x04 // Cookie for Button B (up octave)

uint8_t keystate[4] = {0x00, 0x00, 0x00, 0x00};
// state of the 4 main buttons
bool buttonKeystate[4] = {false, false, false, false};
uint8_t velocity = 0;

// keyboard starts in octave 4, this gets changed by button presses
int octave = 4;

// min and max octives...  10 octives in midi, 
const int minOctave = 0;
const int maxOctave = 10;

//HID Event Handling
void hid_element_value_callback (void *          inContext, 
                                 IOReturn        inResult,
                                 void *          inSender,
                                 IOHIDValueRef   inIOHIDValueRef) {
	
	IOHIDElementRef eref = IOHIDValueGetElement(inIOHIDValueRef);
	IOHIDElementType etype = IOHIDElementGetType(eref);
	IOHIDElementCookie ecookie = IOHIDElementGetCookie(eref);
    const uint8_t *bytes = IOHIDValueGetBytePtr(inIOHIDValueRef);
	
	if (etype == kIOHIDElementTypeInput_Misc &&
		(ecookie == LOWREG_COOKIE ||
		 ecookie == MIDREG_COOKIE || 
		 ecookie == HIGHREG_COOKIE || 
		 ecookie == VELOCITY_COOKIE)) {
        uint8_t updates;
        int index = (int) ecookie - LOWREG_COOKIE;
        uint8_t mask = (ecookie != VELOCITY_COOKIE) ? 0xFF : 0x80;
            
        updates = keystate[index] ^ (bytes[0] & mask);
        keystate[index] = bytes[0] & mask;
			
        if (ecookie == VELOCITY_COOKIE) {
            velocity = bytes[0] & 0x7F;
        }
            
            
        if (updates) {
            uint8_t base_note = (octave * 12) + (index * 8);
            if (0x80 & updates) note_event(base_note, velocity, 0x80 & keystate[index]);
            if (0x40 & updates) note_event(base_note + 1, velocity, 0x40 & keystate[index]);
            if (0x20 & updates) note_event(base_note + 2, velocity, 0x20 & keystate[index]);
            if (0x10 & updates) note_event(base_note + 3, velocity, 0x10 & keystate[index]);
            if (0x08 & updates) note_event(base_note + 4, velocity, 0x08 & keystate[index]);
            if (0x04 & updates) note_event(base_note + 5, velocity, 0x04 & keystate[index]);
            if (0x02 & updates) note_event(base_note + 6, velocity, 0x02 & keystate[index]);
            if (0x01 & updates) note_event(base_note + 7, velocity, 0x01 & keystate[index]);
                
            // XXX - should pack the midi events
            // XXX there are cleaner ways to do this.
        }
    } else if (etype == kIOHIDElementTypeInput_Button &&
		(ecookie == BUTTON_1_COOKIE ||
		 ecookie == BUTTON_B_COOKIE)) {
        // One of the buttons (1,2,A,B)
        int index = (int) ecookie - BUTTON_1_COOKIE;
        // Happens once on "button press" and once for "button release" - only trigger on button press
        buttonKeystate[index] = !buttonKeystate[index];

        if (buttonKeystate[index]) {
        	if (ecookie == BUTTON_1_COOKIE && octave > minOctave) {
        		octave = octave-1;
        	}
        	if (ecookie == BUTTON_B_COOKIE && octave < maxOctave) {
        		octave = octave+1;
        	}
        }
    }
}

// XXX - Presumes midi has been setup
void setup_hid_event_processing() {
    hidmanager = IOHIDManagerCreate(kCFAllocatorDefault, 
									kIOHIDOptionsTypeNone);
	IOHIDManagerScheduleWithRunLoop(hidmanager, CFRunLoopGetMain(), 
									kCFRunLoopDefaultMode);
	//IOReturn ret = 
	IOHIDManagerOpen(hidmanager, 0L);
	
	const long productId = 0x3330;
	const long vendorId = 0x1BAD;
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	[dict setObject:[NSNumber numberWithLong:productId]
			 forKey:[NSString stringWithCString:kIOHIDProductIDKey encoding:NSUTF8StringEncoding]];
	[dict setObject:[NSNumber numberWithLong:vendorId]
			 forKey:[NSString stringWithCString:kIOHIDVendorIDKey encoding:NSUTF8StringEncoding]];
	[dict setObject:[NSString stringWithCString:"Harmonix RB3 Keyboard for Nintendo Wii" encoding:NSUTF8StringEncoding]
			 forKey:[NSString stringWithCString:kIOHIDProductKey encoding:NSUTF8StringEncoding]];
	
	
	IOHIDManagerSetDeviceMatching(hidmanager, (CFMutableDictionaryRef)dict);
	NSSet *allDevices = [((NSSet *)IOHIDManagerCopyDevices(hidmanager)) autorelease]; 
	NSArray *deviceRefs = [allDevices allObjects];
	deviceRef = ([deviceRefs count]) ? (IOHIDDeviceRef)[deviceRefs objectAtIndex:0] : nil;
	
	
	
	if (deviceRef != nil) {
		//IOHIDDeviceCopyMatchingElements(deviceRef, <#CFDictionaryRef matching#>, 0);
        
		
		//size_t bufferSize = 128;
		//char *inputBuffer = malloc(bufferSize);
    	//char *outputBuffer = malloc(bufferSize);
	    //IOHIDDeviceRegisterInputReportCallback(deviceRef, (uint8_t *)inputBuffer, bufferSize,
		//									   keytar_event_callback, NULL);
		IOHIDManagerRegisterInputValueCallback(hidmanager, hid_element_value_callback, NULL);
	}
    
};
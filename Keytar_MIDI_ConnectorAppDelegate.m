//
//  Keytar_MIDI_ConnectorAppDelegate.m
//  Keytar MIDI Connector
//
//  Created by Gregory Keeney on 1/2/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Keytar_MIDI_ConnectorAppDelegate.h"
#include "midiutil.h"
#include "hidutil.h"

@implementation Keytar_MIDI_ConnectorAppDelegate

@synthesize window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    setup_midi();
    setup_hid_event_processing();
}

@end

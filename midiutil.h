/*
 *  midiutil.h
 *  Keytar MIDI Connector
 *
 *  Created by Gregory Keeney on 1/2/11.
 *  Copyright 2011 Gregory Keeney. All rights reserved.
 *
 */

#import <CoreFoundation/CoreFoundation.h>
#import <CoreMIDI/MIDIServices.h>

void note_event(Byte note, Byte velocity, boolean_t on);
void setup_midi();


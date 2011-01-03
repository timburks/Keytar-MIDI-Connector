/*
 *  midiutil.c
 *  Keytar MIDI Connector
 *
 *  Created by Gregory Keeney on 1/2/11.
 *  Copyright 2011 __MyCompanyName__. All rights reserved.
 *
 */

#include "midiutil.h"

MIDIClientRef midiclient;
MIDIPortRef midiport;
MIDIEndpointRef  midiout;

CFStringRef client_name = CFSTR("Keytar MIDI Client");
CFStringRef source_name = CFSTR("Keytar MIDI Source");
CFStringRef port_name = CFSTR("Keytar MIDI Port");

// XXX - We could (should) pack up note changes that occur in the same HID event.
void note_event(Byte note, Byte velocity, boolean_t on) {
	// Prepare a MIDI message to send 
	MIDITimeStamp timestamp = 0;
	Byte buffer[1024]; // XXX - sizing
	MIDIPacketList *packetlist = (MIDIPacketList*)buffer;
	MIDIPacket *currentpacket = MIDIPacketListInit(packetlist);
	
	Byte notebytes[3];
	notebytes[0] = on ? 0x90 : 0x80;
	notebytes[1] = (Byte) note;
	notebytes[2] = (Byte) velocity;
	
	currentpacket = MIDIPacketListAdd(packetlist, sizeof(buffer), 
									  currentpacket, timestamp, 3, notebytes);
	
	MIDIReceived(midiout, packetlist);
};

void setup_midi() {
    OSStatus status;
    
    status = MIDIClientCreate(client_name, NULL, NULL, &midiclient);
 	printf("MIDI Client created, status: %d\n", (int) status);
	
    status = MIDISourceCreate (midiclient, source_name, &midiout);
	printf("Output source. Status: %d\n", (int) status);
    
	status = MIDIOutputPortCreate(midiclient, port_name, &midiport);
	printf("MIDI Output Port created, status: %d\n", (int) status);
}


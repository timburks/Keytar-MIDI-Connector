//
//  main.m
//  keytard
//
//  Created by Tim Burks on 9/25/12.
//
//

#import <Foundation/Foundation.h>
#include "midiutil.h"
#include "hidutil.h"

int main(int argc, const char * argv[])
{
    @autoreleasepool {
        setup_midi();
        setup_hid_event_processing();
        [[NSRunLoop mainRunLoop] runUntilDate:[NSDate distantFuture]];
    }
    return 0;
}


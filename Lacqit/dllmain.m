//
//  dllmain.m
//  Lacqit
//
//  Created by Pauli Ojala on 8.9.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//


#import <windows.h>
#import <stdio.h>


__declspec(dllimport) int OBJCRegisterDLL(HINSTANCE handle);



int APIENTRY DllMain(HINSTANCE handle, DWORD reason, LPVOID _reserved)
{
    if(reason==DLL_PROCESS_ATTACH)
        return OBJCRegisterDLL(handle);

    ///printf("Lacqit dllmain called: reason %u\n", reason);  fflush(stdout);

    return TRUE;
}

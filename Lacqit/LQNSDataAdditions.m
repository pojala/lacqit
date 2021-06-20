//
//  LQNSDataAdditions.m
//  Lacqit
//
//  Created by Pauli Ojala on 26.6.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQNSDataAdditions.h"
#import <zlib.h>


@implementation NSData (LQNSDataAdditions)

- (NSData *)zippedData
{
    size_t srcLen = [self length];
    uint8_t *srcBuf = (uint8_t *)[self bytes];

    if (srcLen < 1 || !srcBuf)
        return nil;
        
    int zret;
    z_stream stream;
    memset(&stream, 0, sizeof(z_stream));
    
	const int deflateQuality = Z_DEFAULT_COMPRESSION;  // default is 6; range 1-9

	if (Z_OK != deflateInit2(&stream, deflateQuality, Z_DEFLATED,
							 15, // windowBits (default 15; range 8-15, or >15 for gzip header, says zlib.h)
							 9,  // memLevel   (default 8; range 1-9)
							 Z_DEFAULT_STRATEGY))  // other useful option is Z_RLE
        return nil;

    // a single buffer for compression
    size_t dstBufSize = srcLen * 1001 / 1000 + 12;  // some extra space in case weird data can't be compressed at all
    uint8_t *dstBuf = NSZoneMalloc(NULL, dstBufSize);  // buffer will be passed to Foundation, so must be alloced with its own malloc wrapper
        
    stream.avail_in = srcLen;
    stream.avail_out = dstBufSize;
    stream.next_in = srcBuf;
    stream.next_out = dstBuf;
    
    zret = deflate(&stream, Z_FINISH);
    
    ///NSLog(@"did deflate, inbytes %i --> outbytes %i", srcLen, stream.total_out);

    deflateEnd(&stream);

    if (zret != Z_STREAM_END) {
        NSLog(@"** %s: failed (%i)", __func__, zret);
        NSZoneFree(NULL, dstBuf);
        return nil;
    } else
        return [NSData dataWithBytesNoCopy:dstBuf length:stream.total_out freeWhenDone:YES];
}


- (NSData *)unzippedDataWithKnownLength:(size_t)expectedSize
{
    size_t srcLen = [self length];
    const uint8_t *srcBuf = [self bytes];

    if (srcLen < 1 || !srcBuf)
        return nil;
        
    //if (expectedSize < 1) {
    //    NSLog(@"** %s: warning - decompression without a size expectation may fail", __func__);
    //    expectedSize = 8 * 1024*1024;  // random guess: 8 megs might be enough?
    //}   
        
    int zret;
    z_stream stream;
    memset(&stream, 0, sizeof(z_stream));

    if (Z_OK != inflateInit(&stream))
        return nil;

    if (expectedSize > 0) {
        // a single buffer for decompression
        uint8_t *dstBuf = NSZoneMalloc(NULL, expectedSize);
                
        stream.avail_in = srcLen;    
        stream.avail_out = expectedSize;
        stream.next_in = (uint8_t *)srcBuf;
        stream.next_out = (uint8_t *)dstBuf;
    
        zret = inflate(&stream, Z_FINISH);
    
        ///NSLog(@"did inflate, inbytes %i --> outbytes %i\n", srcLen, stream.total_out);
        
        inflateEnd(&stream);

        if (zret != Z_STREAM_END) {
            NSLog(@"** %s: failed (%i)", __func__, zret);
            NSZoneFree(NULL, dstBuf);
            return nil;
        } else
            return [NSData dataWithBytesNoCopy:dstBuf length:stream.total_out freeWhenDone:YES];
    }
    else {
        // size is not known beforehand
        size_t tempBufSize = 256*1024;
        NSMutableData *mdata = [NSMutableData dataWithCapacity:tempBufSize];
        uint8_t *tempBuf = NSZoneMalloc(NULL, tempBufSize);
        
        stream.avail_in = srcLen;
        stream.avail_out = tempBufSize;
        stream.next_in = (uint8_t *)srcBuf;
        stream.next_out = (uint8_t *)tempBuf;
        
        while (1) {
            zret = inflate(&stream, Z_SYNC_FLUSH);
            
            if (zret == Z_OK || zret == Z_STREAM_END) {
                size_t lenWritten = tempBufSize - stream.avail_out;
                [mdata appendBytes:tempBuf length:lenWritten];
                
                stream.avail_out = tempBufSize;
                stream.next_out = (uint8_t *)tempBuf;
            }
            if (zret != Z_OK)
                break;
        }

        inflateEnd(&stream);

        if (zret != Z_STREAM_END) {
            NSLog(@"** %s: failed (%i)", __func__, zret);
            mdata = nil;
        }
        
        NSZoneFree(NULL, tempBuf);
        return mdata;
    }
}


#pragma mark --- base64 ---

+ (NSData *)dataFromBase64String:(NSString *)string
{
   NSUInteger      i,length=[string length],resultLength=0;
   unichar       buffer[length];
   uint8_t result[length];
   uint8_t partial=0;
   enum { load6High, load2Low, load4Low, load6Low } state=load6High;
   
   [string getCharacters:buffer];
   
   for(i=0;i<length;i++){
    unichar       code=buffer[i];
    unsigned char bits;
    
    if(code>='A' && code<='Z')
     bits=code-'A';
    else if(code>='a' && code<='z')
     bits=code-'a'+26;
    else if(code>='0' && code<='9')
     bits=code-'0'+52;
    else if(code=='+')
     bits=62;
    else if(code=='/')
     bits=63;
    else if(code=='='){
     break;
    }
    else
     continue;
     
    switch(state){
    
     case load6High:
      partial=bits<<2;
      state=load2Low;
      break;
    
     case load2Low:
      partial|=bits>>4;
      result[resultLength++]=partial;
      partial=bits<<4;
      state=load4Low;
      break;
     
     case load4Low:
      partial|=bits>>2;
      result[resultLength++]=partial;
      partial=bits<<6;
      state=load6Low;
      break;

     case load6Low:
      partial|=bits;
      result[resultLength++]=partial;
      state=load6High;
      break;
    }
   }
   
   return [NSData dataWithBytes:result length:resultLength];
}

- (NSString *)encodeAsBase64String
{
    static const char b64[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    NSUInteger y, n;
    const NSUInteger len = [self length];
    const uint8_t *bytes = [self bytes];

    NSMutableString *outString = [NSMutableString string];

    const NSUInteger numRows = 1 + len / 45;   // 60 chars per output row -> 45 input bytes per row
    uint8_t srcBuf[48];
    uint8_t dstBuf[64];
    
    n = 0;
    for (y = 0; y < numRows; y++) {
        const NSUInteger rowSrcLen = (y < numRows - 1) ? 45 : (len - n);

        memcpy(srcBuf, bytes + n, rowSrcLen);
        n += rowSrcLen;
        
        if (rowSrcLen < 45)
            memset(srcBuf + rowSrcLen, 0, 45 - rowSrcLen);

        unsigned char *inBuf = srcBuf;
        unsigned char *outBuf = dstBuf;
        int x;
        for (x = 0; x < rowSrcLen; x += 3) {
            const NSInteger blockLen = (x + 3 < rowSrcLen) ? 3 : (rowSrcLen - x);
            
            // base64 encode
            outBuf[0] = b64[ inBuf[0] >> 2 ];
            outBuf[1] = b64[ ((inBuf[0] & 0x03) << 4) | ((inBuf[1] & 0xf0) >> 4) ];
            outBuf[2] = (unsigned char) (blockLen > 1) ? b64[ ((inBuf[1] & 0x0f) << 2) | ((inBuf[2] & 0xc0) >> 6) ] : '=';
            outBuf[3] = (unsigned char) (blockLen > 2) ? b64[ inBuf[2] & 0x3f ] : '=';
            inBuf += 3;
            outBuf += 4;
        }
        if (y < numRows-1) {
            *outBuf++ = (unsigned char)'\n';
        }
        *outBuf = 0;
        
        //[outData appendBytes:dstBuf length:(outBuf - dstBuf + 1)];
        [outString appendString:[NSString stringWithCString:(char *)dstBuf encoding:NSUTF8StringEncoding]];
    }
    
    return outString;
}

@end

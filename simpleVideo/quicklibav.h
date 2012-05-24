//
//  quicklibav.h
//  testlibav
//
//  Created by star king on 12-5-16.
//  Copyright (c) 2012年 elegant cloud. All rights reserved.
//

#ifndef testlibav_quicklibav_h
#define testlibav_quicklibav_h
#include "libavformat/avformat.h"

#define STREAM_FRAME_RATE   15
#define STREAM_PIX_FMT      PIX_FMT_YUV420P

typedef struct QuickVideoOutput {
    AVFormatContext *video_output_context;
    AVStream *video_stream;
    int width;
    int height;
} QuickVideoOutput;

/*
 * alloc a new picture 
 * @return picture need to be freed by user (call av_free())
 */
AVFrame * alloc_picture(enum PixelFormat pix_fmt, int width, int height);

/* 
 * initialize quick video output including AVFormatContext, AVStream, AVCodecContext etc.
 * and also prepare the environment for using libav
 * @param[out] qvo: QuickVideoOutput
 * @param[in] filename: the file to write
 * @param[in] type: the type of format
 * @return zero on success or negative value on failure
 */
int init_quick_video_output(QuickVideoOutput *qvo, const char *filename, const char *type);

/*
 * free the resource of QuickVideoOuput
 * @param[in] qvo: QuickVideoOutput
 */
void close_quick_video_ouput(QuickVideoOutput *qvo);

/* 
 * encode raw picture and write out the encoded frame
 * @param[in] qvo: QuickVideoOutput
 * @param[in] raw_picture: raw picture from camera etc.
 * @return output size (>=0) on success or negative value on failure
 */
int write_video_frame(QuickVideoOutput *qvo, AVFrame *raw_picture);

#endif

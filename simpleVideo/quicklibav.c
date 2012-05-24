//
//  quicklibav.c
//  quick functions for libav
//
//  Created by star king on 12-5-15.
//  Copyright (c) 2012年 elegant cloud. All rights reserved.
//

#include <stdio.h>
#include "quicklibav.h"
#include "libavcodec/avcodec.h"
#include "libavutil/imgutils.h"

static uint8_t *video_outbuf = NULL;
static int video_outbuf_size = 20000;


AVFrame * alloc_picture(enum PixelFormat pix_fmt, int width, int height) {
    AVFrame *picture = avcodec_alloc_frame();
    if (!picture) {
        return NULL;
    }
    
    av_image_alloc(picture->data, picture->linesize, width, height, pix_fmt, 1);
    //avpicture_alloc((AVPicture *)picture, pix_fmt, width, height);
   
    /*
    int size = avpicture_get_size(pix_fmt, width, height);
    uint8_t *picture_buf = av_malloc(size);
    if (!picture_buf) {
        av_free(picture);
        return NULL;
    }
    
    avpicture_fill((AVPicture *)picture, picture_buf, pix_fmt, width, height);
    */
    return picture;
}


/**
 * find specified encoder and create new stream
 * And open the codec
 */
static AVStream * create_video_stream(AVFormatContext *oc, enum CodecID codec_id, int width, int height) {
    AVCodecContext *c;
    AVStream *st;
    AVCodec *codec;
    
    /* find the video encoder */
    codec = avcodec_find_encoder(codec_id);
    if (!codec) {
        fprintf(stderr, "codec not found\n");
        return NULL;
    }
    
    st = avformat_new_stream(oc, codec);
    if (!st) {
        fprintf(stderr, "Could not alloc stream\n");
        return NULL;
    }
    
    printf("new video stream time base: %d / %d\n", st->time_base.num, st->time_base.den);
    
    c = st->codec;
    
    /**** set codec parameters ****/
    /* put sample parameters */
    //c->bit_rate = 4000;
    /* resolution must be a multiple of two */
    c->width = width;
    c->height = height;
    /* frames per second */
    c->time_base = (AVRational){1, STREAM_FRAME_RATE};
    c->gop_size = 12; /* emit one intra frame every ten frames */

   // c->max_b_frames=0;
   // c->b_frame_strategy = 0;
    
    c->pix_fmt = STREAM_PIX_FMT;
    /*
    c->me_range = 16;
    c->max_qdiff = 4;
    c->qmin = 10;
    c->qmax = 51;
    c->qcompress = 0.6; 
    */
    c->level = 10; //Level 
    //c->profile = FF_PROFILE_H264_CONSTRAINED_BASELINE; //Baseline
    
    if (oc->oformat->flags & AVFMT_GLOBALHEADER) {
        c->flags |= CODEC_FLAG_GLOBAL_HEADER;
    }
    
    AVDictionary *dict = NULL;
    av_dict_set(&dict, "profile", "baseline", 0);
    
    /* open video codec */
    if (avcodec_open2(c, codec, &dict) < 0) {
        fprintf(stderr, "Could not open codec\n");
        av_dict_free(&dict);
        return NULL;
    }
    
    av_dict_free(&dict);
    
    return st;
}

int init_quick_video_output(QuickVideoOutput *qvo, const char *filename, const char *type) {
    int ret = 0;
    if (qvo == NULL) {
        return -1;
    }
    
    av_register_all();
   
    avformat_network_init();
    
    AVOutputFormat *fmt = av_guess_format(type, filename, NULL);
    if (!fmt) {
        fprintf(stderr, "Could not find suitable output format!\n");
        return -1;
    }
    
    /* allocate the output media context */
    AVFormatContext *oc = avformat_alloc_context();
    if (!oc) {
        fprintf(stderr, "Memory error when allocating AVFormatContext!\n");
        return -1;
    }
    
    fmt->video_codec = CODEC_ID_H264;
    oc->oformat = fmt;
    snprintf(oc->filename, sizeof(oc->filename), "%s", filename);
    qvo->video_output_context = oc;
    
    AVStream *video_st = create_video_stream(oc, fmt->video_codec, qvo->width, qvo->height);
    if (!video_st) {
        fprintf(stderr, "Could not add video stream\n");
        return -1;
    }
    qvo->video_stream = video_st;
    
    /* init out buffer */
    video_outbuf_size = 100000 + 12 * video_st->codec->width * video_st->codec->height;
    video_outbuf = av_malloc(video_outbuf_size);
    
    av_dump_format(oc, 0, filename, 1);
    
    /* open the output file, if needed */
    if (!(fmt->flags & AVFMT_NOFILE)) {
        printf("try to open file: %s\n", filename);
        if (avio_open(&oc->pb, filename, AVIO_FLAG_WRITE) < 0) {
            fprintf(stderr, "Could not open '%s'\n", filename);
            return -1;
        } else {
            printf("file open ok\n");
        }
    }
    
    
    printf("video stream time base: %d / %d - codec time base: %d / %d\n",video_st->time_base.num, video_st->time_base.den, video_st->codec->time_base.num, video_st->codec->time_base.den);
    
    /* write the stream header, if any */
    avformat_write_header(oc, NULL);
    
    return ret;
}


void close_quick_video_ouput(QuickVideoOutput *qvo) {
    if (!qvo) {
        return;
    }
    
    AVFormatContext *oc = qvo->video_output_context;
    AVStream *st = qvo->video_stream;
    
    if (oc) {
        av_write_trailer(oc);
    }
     
    avformat_network_deinit();
    
    if (st && st->codec) {
        avcodec_close(st->codec);
    }
    
    if (video_outbuf) {
        av_free(video_outbuf);
    }
    
    if (oc) {
        /* free the streams */
        for (int i = 0; i < oc->nb_streams; i++) {
            av_freep(&oc->streams[i]->codec);
            av_freep(&oc->streams[i]);
        }
        if (!(oc->oformat->flags & AVFMT_NOFILE)) {
            /* close the output file */
            printf("close output file %s\n", oc->filename);
            avio_close(oc->pb);
        }
        
        /* free the stream */
        av_free(oc);
    }
    
    
}


int write_video_frame(QuickVideoOutput *qvo, AVFrame *raw_picture) {
    if (!qvo || !qvo->video_stream || !qvo->video_output_context) {
        return -1;
    }
    
    AVCodecContext *c = qvo->video_stream->codec;
    if (!c) {
        return -1;
    }
    
    AVFormatContext *oc = qvo->video_output_context;
    
    int ret = 0;
    
    /* encode the image */
    int out_size = avcodec_encode_video(c, video_outbuf, video_outbuf_size, raw_picture);
    /* if size is zero, it means the image was buffered */
    if (out_size > 0) {
        AVPacket pkt;
        av_init_packet(&pkt);
        
        if (c->coded_frame->pts != AV_NOPTS_VALUE) {
            pkt.pts = av_rescale_q(c->coded_frame->pts, c->time_base, qvo->video_stream->time_base);
        }
        
        if (c->coded_frame->key_frame) {
            pkt.flags |= AV_PKT_FLAG_KEY;
        }
        
        pkt.stream_index = qvo->video_stream->index;
        pkt.data = video_outbuf;
        pkt.size = out_size;
    
        /*
        printf("pkt pts: %lld c->time_base: %d / %d vt->time_base: %d / %d\n", pkt.pts, c->time_base.num, c->time_base.den, qvo->video_stream->time_base.num, qvo->video_stream->time_base.den);
        */
        
        /* wite the compressed frame to the media file */
        ret = av_interleaved_write_frame(oc, &pkt);
    } else {
        ret = 0;
    }
    
    if (ret != 0) {
        fprintf(stderr, "error while writing video frame\n");
        return -1;
    }
    
    return out_size;
    
}



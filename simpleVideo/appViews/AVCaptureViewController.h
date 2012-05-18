//
//  AVCaptureViewController.h
//  simpleVideo
//
//  Created by  on 12-4-12.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <AVFoundation/AVFoundation.h>
#import "quicklibav.h"
#import "libswscale/swscale.h"

@interface AVCaptureViewController : UIViewController<AVCaptureVideoDataOutputSampleBufferDelegate>{
    // UI view
    // video state label
    UILabel *_mVideoStateLabel;
    // video display view
    UIView *_mVideoDisplayView;
    
    // local video view
    UIImageView *_mLocalVideoView;
    // custom layer
    CALayer *_customLayer;
    
    // av capture session
    AVCaptureSession *_avCaptureSession;
    // av capture device
    AVCaptureDevice *_avCaptureDevice;
    
    // is or not first frame
    BOOL _firstFrame; 
    // fps value
    int _producerFps;
    
    QuickVideoOutput *qvo;
    AVFrame *raw_picture; 
    AVFrame *tmp_picture;
    
    struct SwsContext *img_convert_ctx;
    double video_pts;
}

// init UI control
-(void) initControl;

// get device front camera
-(AVCaptureDevice*) getFrontCamera;

// start capture video
-(void) startCaptureVideo;
// stop capture video
-(void) stopCaptureVideo:(id)pArg;

@end

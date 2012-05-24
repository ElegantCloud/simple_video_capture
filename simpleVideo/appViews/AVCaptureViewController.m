//
//  AVCaptureViewController.m
//  simpleVideo
//
//  Created by  on 12-4-12.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "AVCaptureViewController.h"

#import <QuartzCore/QuartzCore.h>
#import <stdio.h>

@implementation AVCaptureViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        // set background color
        self.view.backgroundColor= [UIColor lightGrayColor];
        
        // update view center
        self.view.center = CGPointMake(self.view.center.x, self.view.center.y-20.0);
        
        // create and init UI control
        [self initControl];
        
        // init variable
        _firstFrame = YES;
        _producerFps = STREAM_FRAME_RATE;
        //dest = @"rtmp://192.168.1.233/flvplayback/star live=1 conn=S:sk";
        dest = @"rtmp://122.96.24.173/quick_server/iphone live=1 conn=S:sk_test";
        //dest = @"rtp://192.168.1.233:10000";
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
}
*/

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
}
*/

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return interfaceOrientation == UIInterfaceOrientationPortrait;
}

// AVCaptureVideoDataOutputSampleBufferDelegate methods implemetation
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
    NSLog(@"capture output..");
    // 捕捉数据输出 要怎么处理随你便
    CVPixelBufferRef _pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    /*Lock the buffer*/
    if(CVPixelBufferLockBaseAddress(_pixelBuffer, 0) == kCVReturnSuccess){
        //UInt8 *_bufferPtr = (UInt8 *)CVPixelBufferGetBaseAddress(_pixelBuffer);
        //size_t _buffeSize = CVPixelBufferGetDataSize(_pixelBuffer);
        
        if(_firstFrame){
            if(1){
                // 第一次数据要求：宽高，类型
                //int _width = CVPixelBufferGetWidth(_pixelBuffer);
                //int _height = CVPixelBufferGetHeight(_pixelBuffer);
                
                int _pixelFormat = CVPixelBufferGetPixelFormatType(_pixelBuffer);
                
                switch (_pixelFormat) {
                    case kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange:
                        //TMEDIA_PRODUCER(producer)->video.chroma = tmedia_nv12; // iPhone 3GS or 4
                        NSLog(@"Capture pixel format=NV12");
                        break;
                    case kCVPixelFormatType_422YpCbCr8:
                        //TMEDIA_PRODUCER(producer)->video.chroma = tmedia_uyvy422; // iPhone 3
                        NSLog(@"Capture pixel format=UYUY422");
                        break;
                    case kCVPixelFormatType_32BGRA:
                        NSLog(@"Capture pixel format=RGB32");
                        break;     
                    default:
                        //TMEDIA_PRODUCER(producer)->video.chroma = tmedia_rgb32;
                        NSLog(@"Capture pixel format=RGB32");
                        break;
                }
                
                _firstFrame = NO;
            }
        }
        /*We unlock the buffer*/
        CVPixelBufferUnlockBaseAddress(_pixelBuffer, 0); 
    }
    
    /*We create an autorelease pool because as we are not in the main_queue our code is
     not executed in the main thread. So we have to create an autorelease pool for the thread we are in*/
    @autoreleasepool {
        // Code, such as a loop that creates a large number of temporary objects.
        CVImageBufferRef _imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer); 
        /*Lock the image buffer*/
        CVPixelBufferLockBaseAddress(_imageBuffer,0); 
        /*Get information about the image*/
        uint8_t *_baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(_imageBuffer); 
        size_t _bytesPerRow = CVPixelBufferGetBytesPerRow(_imageBuffer); 
        size_t _width = CVPixelBufferGetWidth(_imageBuffer); 
        size_t _height = CVPixelBufferGetHeight(_imageBuffer);  
        
      //  NSLog(@"raw image width: %zul heigth: %zul ", _width, _height);
         
        
        
        /*Create a CGImageRef from the CVImageBufferRef*/
        
        CGColorSpaceRef _colorSpace = CGColorSpaceCreateDeviceRGB(); 
        if (_colorSpace == nil) {
            NSLog(@"CGColorSpaceCreateDeviceRGB failure");
            
            return ;
        }
        
        // get image
        CGContextRef _newContext = CGBitmapContextCreate(_baseAddress, _width, _height, 8, _bytesPerRow, _colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
        CGImageRef _newImage = CGBitmapContextCreateImage(_newContext); 
        
        CGContextRelease(_newContext); 
        
        // another to get image
        /*
        size_t _bufferSize = CVPixelBufferGetDataSize(_imageBuffer); 
        
        // Create a Quartz direct-access data provider that uses data we supply
        CGDataProviderRef _provider = CGDataProviderCreateWithData(NULL, _baseAddress, _bufferSize, NULL);
        // Create a bitmap image from data supplied by our data provider
        CGImageRef cgImage = CGImageCreate(_width, _height, 8, 32, _bytesPerRow, _colorSpace, kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder32Little, _provider, NULL, true, kCGRenderingIntentDefault);
        CGDataProviderRelease(_provider);
         */
        
        /*We release some components*/
        CGColorSpaceRelease(_colorSpace);
        
        /* We display the result on the custom layer. All the display stuff must be done in the 
         * main thread because UIKit is no thread safe, and as we are not in the main thread 
         * (remember we didn't use the main_queue) we use performSelectorOnMainThread to call our 
         * CALayer and tell it to display the CGImage.
         */
       // [_customLayer performSelectorOnMainThread:@selector(setContents:) withObject:(__bridge id)_newImage waitUntilDone:YES];

        /* We display the result on the image view (We need to change the orientation of the image 
         * so that the video is displayed correctly). Same thing as for the CALayer we are not in 
         * the main thread so ...
         */
        UIImage *_image= [UIImage imageWithCGImage:_newImage /*scale:1.0 orientation:nil*/];
    
        /*We relase the CGImageRef*/
        CGImageRelease(_newImage);
         
        [_mLocalVideoView performSelectorOnMainThread:@selector(setImage:) withObject:_image waitUntilDone:YES];
        
        
        /*We unlock the  image buffer*/
        CVPixelBufferUnlockBaseAddress(_imageBuffer,0);
        
        [self process_raw_frame:_baseAddress andWidth:_width andHeight:_height];

    }
}

-(void) process_raw_frame: (uint8_t *)buffer_base_address andWidth: (int)width andHeight: (int)height{
    NSLog(@"origin image width: %d height: %d", width, height);    
    
    if (!qvo) {
        return;
    }
    
    
    AVCodecContext *c = qvo->video_stream->codec;
    
    avpicture_fill((AVPicture *)tmp_picture, buffer_base_address, src_pix_fmt, width, height);
    NSLog(@"raw picture to encode width: %d height: %d", c->width, c->height);

    img_convert_ctx = sws_getCachedContext(img_convert_ctx, width, height, src_pix_fmt, qvo->width, qvo->height, c->pix_fmt, SWS_BILINEAR, NULL, NULL, NULL);

    // convert RGB32 to YUV420
    sws_scale(img_convert_ctx, tmp_picture->data, tmp_picture->linesize, 0, height, raw_picture->data, raw_picture->linesize);
    
    int out_size = write_video_frame(qvo, raw_picture);
   
   // NSLog(@"stream pts val: %lld time base: %d / %d",qvo->video_stream->pts.val, qvo->video_stream->time_base.num, qvo->video_stream->time_base.den);
    video_pts = (double)qvo->video_stream->pts.val * qvo->video_stream->time_base.num / qvo->video_stream->time_base.den;
    NSLog(@"write video frame - size: %d video pts: %f", out_size, video_pts);
    
    raw_picture->pts++;
    
}

// methods implemetation
-(void) initControl{
    // cretae and init UI subView
    // video state label
    _mVideoStateLabel= [[UILabel alloc] initWithFrame:CGRectMake(10.0, 10.0, self.view.frame.size.width-2*10.0, 36.0)];
    // set background color
    _mVideoStateLabel.backgroundColor= [UIColor clearColor];
    // set text and font
    // set default text
    _mVideoStateLabel.text = NSLocalizedString(@"video state default string", "video state default string");
    _mVideoStateLabel.textColor = [UIColor whiteColor];
    _mVideoStateLabel.textAlignment = UITextAlignmentCenter;
    _mVideoStateLabel.font = [UIFont boldSystemFontOfSize:22.0];
    // add to view
    [self.view addSubview:_mVideoStateLabel];
    
    // video display view
    _mVideoDisplayView= [[UIView alloc] initWithFrame:CGRectMake(_mVideoStateLabel.frame.origin.x/2, _mVideoStateLabel.frame.origin.y+_mVideoStateLabel.frame.size.height+10.0, _mVideoStateLabel.frame.size.width+_mVideoStateLabel.frame.origin.x, self.view.frame.size.height-4*10.0-2*36.0)];
    // set layer
    _mVideoDisplayView.layer.cornerRadius = 4.0;
    _mVideoDisplayView.layer.masksToBounds = YES;
    _mVideoDisplayView.layer.borderWidth = 1.0;
    _mVideoDisplayView.layer.borderColor = [[UIColor darkGrayColor] CGColor];
    // add to view
    [self.view addSubview:_mVideoDisplayView];
    
    // local video display view
    _mLocalVideoView = [[UIImageView alloc] initWithFrame:CGRectMake(0 /*_mVideoDisplayView.frame.origin.x*/ /*+_mVideoDisplayView.frame.size.width-80.0-2.0*/, 0 /*_mVideoDisplayView.frame.origin.y*/ /*+_mVideoDisplayView.frame.size.height-106.7-2.0*/, 320, 428)];
    // set layer
    _mLocalVideoView.layer.cornerRadius = 4.0;
    _mLocalVideoView.layer.masksToBounds = YES;
    // add sub layer
    [_mLocalVideoView.layer addSublayer:_customLayer];
    // add to view
    [self.view addSubview:_mLocalVideoView];
    
    // start cemera capture button
    UIButton* _startVideoBtn= [UIButton buttonWithType:UIButtonTypeRoundedRect];
    // set frame
    _startVideoBtn.frame = CGRectMake(self.view.frame.size.width/2-80.0-10.0, self.view.frame.size.height-36.0-10.0, 80.0, 36.0);
    // set title
    [_startVideoBtn setTitle:NSLocalizedString(@"start cemera capture button title", "start cemera capture button title") forState:UIControlStateNormal];
    // add target
    [_startVideoBtn addTarget:self action:@selector(startCaptureVideo) forControlEvents:UIControlEventTouchUpInside];
    // add to view
    [self.view addSubview:_startVideoBtn];
    
    // stop cemara capture button
    UIButton* _stopVideoBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    // set frame
    _stopVideoBtn.frame = CGRectMake(self.view.frame.size.width/2+10.0, _startVideoBtn.frame.origin.y, _startVideoBtn.frame.size.width, _startVideoBtn.frame.size.height);
    // set title
    [_stopVideoBtn setTitle:NSLocalizedString(@"stop cemera capture button title", "stop cemera capture button title") forState:UIControlStateNormal];
    // add target
    [_stopVideoBtn addTarget:self action:@selector(stopCaptureVideo:) forControlEvents:UIControlEventTouchUpInside];
    // add to view
    [self.view addSubview:_stopVideoBtn];
}

-(AVCaptureDevice*) getFrontCamera{
    AVCaptureDevice *_ret = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    // get device front camera device
    NSArray *_cameras = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    //NSLog(@"device cameras = %@", _cameras);
    
    for(AVCaptureDevice *_cemera in _cameras){
        if (_cemera.position == /*AVCaptureDevicePositionFront*/ AVCaptureDevicePositionBack){
            _ret = _cemera;
            
            break;
        }
    }
    
    return _ret;
}

-(void) startCaptureVideo{
    // initialize QuickVideoOutput
    qvo = (QuickVideoOutput*)malloc(sizeof(QuickVideoOutput));
    
    NSString *filename = @"output.flv";
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    // the path to write file
    NSString *videoFile = [documentsDirectory stringByAppendingPathComponent:filename];

    qvo->width = /*192*/144;
    qvo->height = /*144*/192;
    int ret = init_quick_video_output(qvo, [dest cString], "flv");
    if (ret < 0) {
        NSLog(@"quick video ouput initial failed");
        free(qvo);
        qvo = NULL;
        return;
    }
    enum PixelFormat dst_pix_fmt = qvo->video_stream->codec->pix_fmt;
    src_pix_fmt = PIX_FMT_RGB32;
    
    raw_picture = alloc_picture(dst_pix_fmt, qvo->width, qvo->height);
    tmp_picture = avcodec_alloc_frame();
    raw_picture->pts = 0;
    
    video_pts = 0;
    
    // update video state label string, starting capture
    _mVideoStateLabel.text = NSLocalizedString(@"starting Video stream", "starting capture cemera stream string");
    
    // update video state label string, starting capture
    if(_avCaptureDevice || _avCaptureSession){
        _mVideoStateLabel.text = NSLocalizedString(@"already capturing", "already capturing string");
        
        return;
    }
    
    // update video state label string, can't get valide capture device
    if((_avCaptureDevice = [self getFrontCamera]) == nil){
        _mVideoStateLabel.text = NSLocalizedString(@"failed to get valide capture device", "failed to get valide capture device string");
        
        return;
    }
    
    // update video state label string, can't get video input
    NSError *error = nil;
    AVCaptureDeviceInput *_videoInput = [AVCaptureDeviceInput deviceInputWithDevice:_avCaptureDevice error:&error];
    // judge video input
    if (_videoInput == nil){
        _mVideoStateLabel.text = NSLocalizedString(@"failed to get video input", @"failed to get video input string");
        
        // set avCaptureDevice is nil
        _avCaptureDevice = nil;
        
        return;
    }
        
    // open camera and begin to capture
    // init avCaptureSession
    _avCaptureSession = [[AVCaptureSession alloc] init];
    _avCaptureSession.sessionPreset = AVCaptureSessionPresetLow;
    [_avCaptureSession addInput:_videoInput];
    
    /* Currently, the only supported key is kCVPixelBufferPixelFormatTypeKey. Recommended pixel 
     * format choices are kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange or 
     * kCVPixelFormatType_32BGRA. On iPhone 3G, the recommended pixel format choices are 
     * kCVPixelFormatType_422YpCbCr8 or kCVPixelFormatType_32BGRA.
     */
    // create and init avCaptureVideoDataOutput, and settings
    AVCaptureVideoDataOutput *_avCaptureVideoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    [_avCaptureVideoDataOutput setAlwaysDiscardsLateVideoFrames:YES];
    NSDictionary *_settings = [[NSDictionary alloc] initWithObjectsAndKeys:
                               [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA], kCVPixelBufferPixelFormatTypeKey, nil
                               ];
    _avCaptureVideoDataOutput.videoSettings = _settings;
    
    /*We create a serial queue to handle the processing of our frames*/
    dispatch_queue_t queue = dispatch_queue_create("elegantcloud", NULL);
    [_avCaptureVideoDataOutput setSampleBufferDelegate:self queue:queue];
    [_avCaptureSession addOutput:_avCaptureVideoDataOutput];
    dispatch_release(queue);
    
    AVCaptureConnection *videoConnection = nil;
    for (AVCaptureConnection *connection in _avCaptureVideoDataOutput.connections) {
        for (AVCaptureInputPort *port in [connection inputPorts]) {
            if ([[port mediaType] isEqual:AVMediaTypeVideo] ) {
                videoConnection = connection;
                break;
            }
        }
        if (videoConnection) { break; }
    }
    if (videoConnection) {
        videoConnection.videoMinFrameDuration = CMTimeMake(1, _producerFps);
       // videoConnection.videoMaxFrameDuration = videoConnection.videoMinFrameDuration;
        if (videoConnection.isVideoOrientationSupported) {
            videoConnection.videoOrientation = AVCaptureVideoOrientationPortrait;
        }
    }
    
    /*
    // create and init avCaptureVideoPreviewLayer
    AVCaptureVideoPreviewLayer* _previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:_avCaptureSession];
    // set frame
    _previewLayer.frame = _mVideoDisplayView.bounds;
    _previewLayer.videoGravity= AVLayerVideoGravityResizeAspectFill;
    [_mVideoDisplayView.layer addSublayer: _previewLayer];
    */
     
    _firstFrame= YES;
    [_avCaptureSession startRunning];
    
    // update video state label string, video capture started 
    _mVideoStateLabel.text = NSLocalizedString(@"video capture started", "video capture started string");
}

-(void)stopCaptureVideo:(id)pArg{
    // stop cemara capture
    if(_avCaptureSession){
        [_avCaptureSession stopRunning];
        
        // set avCaptureSession nil
        _avCaptureSession = nil;
        
        // update video state label string, video capture stopped 
        _mVideoStateLabel.text = NSLocalizedString(@"video capture stopped", @"video capture stopped string");
    }
    else{
        // update video state label string, default text 
        _mVideoStateLabel.text = NSLocalizedString(@"video state default string", "video state default string");
    }
    
    // set avCaptureDevice nil
    _avCaptureDevice= nil;
    
    // remove all sub views in localView
    for(UIView *_subView in _mVideoDisplayView.subviews) {
        [_subView removeFromSuperview];
    }

    /*
    // write the delayed frames
    int out_size = 0;
    do {
        out_size = write_video_frame(qvo, NULL);
    } while (out_size > 0);
    */
    
    // close quick video output
    if (qvo != NULL) {
        close_quick_video_ouput(qvo);
        free(qvo);
        qvo = NULL;
    }
    
    if (raw_picture) {
        if (raw_picture->data[0]) {
            av_free(raw_picture->data[0]);
        }
        av_free(raw_picture);
        raw_picture = NULL;
    }
    
    if (tmp_picture) {
        av_free(tmp_picture);
        tmp_picture = NULL;
    }
}

@end

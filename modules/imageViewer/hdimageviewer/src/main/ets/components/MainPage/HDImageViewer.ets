/*
 * Copyright (C) 2025 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import { common2D, drawing } from '@kit.ArkGraphics2D';
import { image } from '@kit.ImageKit';
import { BusinessError, systemDateTime } from '@kit.BasicServicesKit';
import { DrawableDescriptor, FrameCallback, display } from "@kit.ArkUI";
import media from "@ohos.multimedia.image";
import hiTraceMeter from "@ohos.hiTraceMeter";
import hilog from "@ohos.hilog";
import { fileIo } from '@kit.CoreFileKit';

const TAG = 'HDImageViewer';
const DOMAIN = 0xcdef;

class HDFrameCallback extends FrameCallback {
  private func: Function | null = null;

  constructor(func: Function) {
    super();
    this.func = func;
  }

  onFrame(frameTimeNanos: number) {
    if(this.func) {
      this.func();
    }
  }
}

class HDDrawModifier extends DrawModifier {
  public controller: HDImageViewer.Controller | null = null;
  private uiContext: UIContext | null = null;
  private frameCallback: FrameCallback | null = null;
  private startTime: number = 0;
  private endTime: number = 0;
  private lastEndTime: number = 0;

  constructor(uiContext: UIContext) {
    super();
    this.uiContext = uiContext;
    this.frameCallback = new HDFrameCallback(() => {
      this.invalidate();
    })
  }

  private log(message: string): void {
    if (this.controller?.isDebug()) {
      hilog.debug(DOMAIN, TAG, message);
    }
  }

  public doInvalidate() {
    this.uiContext?.postFrameCallback(this.frameCallback);
  }

  async drawContent(context: DrawContext): Promise<void>
  {
    if (this.controller == null) {
      return;
    }
    if (this.controller?.isDebug()) {
      this.startTime = systemDateTime.getUptime(systemDateTime.TimeType.ACTIVE, false);
      if (this.lastEndTime != 0) {
        this.log(`drawContent since last time ${this.startTime - this.lastEndTime}ms`);
      } else {
        this.log(`drawContent start`);
      }
    }

    this.controller?.onDraw(context);

    if (this.controller?.isDebug()) {
      this.endTime = systemDateTime.getUptime(systemDateTime.TimeType.ACTIVE, false);
      this.log(`drawContent cost ${this.endTime - this.startTime}, since last time ${this.endTime - this.lastEndTime}`);
      this.lastEndTime = this.endTime;
    }
  }
}

@Component
struct HDImageViewer {
  @Link @Watch('onSrcChange') srcInfo: HDImageViewer.ImageResourceInfo;
  controller: HDImageViewer.Controller | null = null;
  private modifier: HDDrawModifier = new HDDrawModifier(this.getUIContext());
  private panOption: PanGestureOptions = new PanGestureOptions({fingers: 1, direction: PanDirection.None});
  private panOption2: PanGestureOptions = new PanGestureOptions({fingers: 2, direction: PanDirection.All});

  private startOffsetX: number = 0;
  private startOffsetY: number = 0;
  private startScale: number = 0;

  private log(message: string): void {
    if (this.controller?.isDebug()) {
      hilog.debug(DOMAIN, TAG, message);
    }
  }
  private info(message: string): void {
    hilog.info(DOMAIN, TAG, message);
  }

  aboutToAppear() {
    if (this.controller == null) {
      this.info('Create a controller');
      this.controller = new HDImageViewer.Controller();
    } else {
      this.info('Using an external controller');
    }
    if (this.controller) {
      this.modifier.controller = this.controller;
      this.controller.modifier = this.modifier;
      this.controller.panOption = this.panOption;
      this.controller.setImage(this.srcInfo.src, this.srcInfo.previewSrc);
    }
  }

  aboutToDisappear(): void {
    this.info('aboutToDisappear');
    this.controller?.recycle();
  }

  onSrcChange() {
    this.log('onSrcChange');
    this.controller?.setImage(this.srcInfo.src, this.srcInfo.previewSrc);
  }

  build() {
    Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
      Image('')
        .drawModifier(this.modifier)
        .draggable(false)
        .renderFit(RenderFit.RESIZE_COVER)
        .width('100%')
        .height('100%')
        .onSizeChange((oldValue: SizeOptions, newValue: SizeOptions) => {
          if ((typeof newValue.width === 'number') && (typeof newValue.height === 'number')) {
            this.controller?.setView(vp2px(newValue.width), vp2px(newValue.height));
          }
        })
        .parallelGesture(
          PinchGesture({ fingers: 2, distance: 1 })
            .onActionStart((event) => {
              this.startScale = 1;
            })
            .onActionUpdate((event) => {
              if (!!event) {
                this.controller?.pinch(event.scale / this.startScale,
                  vp2px(event.pinchCenterX), vp2px(event.pinchCenterY));
                this.startScale = event.scale;
              }
            })
            .onActionEnd((event) => {
              this.controller?.scalePlayBack(
                vp2px(event.pinchCenterX), vp2px(event.pinchCenterY));
            }))
        .gesture(
          GestureGroup(GestureMode.Parallel,
            // Register an empty implementation of the two-finger swipe event to avoid misidentifying
            // the two-finger swipe tiling event as the parent component in the first place.
            PanGesture(this.panOption2),
            PanGesture(this.panOption)
              .onActionStart((event:GestureEvent) => {
                this.startOffsetX = 0;
                this.startOffsetY = 0;
              })
              .onActionUpdate((event:GestureEvent) => {
                if (!!event) {
                  this.controller?.pan(
                    vp2px(event.offsetX - this.startOffsetX), vp2px(event.offsetY - this.startOffsetY));
                  this.startOffsetX = event.offsetX;
                  this.startOffsetY = event.offsetY;
                }
              })
              .onActionEnd((event) => {
                if (!this.controller?.isReady()) {
                  return;
                }

                this.log("PanGestureEnd offsetX:" + event.offsetX + ", offsetY:" + event.offsetY
                  + ", velocityX: " + event.velocityX + ", velocityY: " + event.velocityY);
                if (Math.abs(event.velocityX) > 500 || Math.abs(event.velocityY) > 500) {
                  let anim = this.controller?.newAnimBuilder();
                  let centerNow = this.controller?.getCenter();
                  let centerEnd: common2D.Point = {
                    x: centerNow.x - event.velocityX * 1.0 / this.controller?.getScale(),
                    y: centerNow.y - event.velocityY * 1.0 / this.controller?.getScale()
                  }
                  anim.setCenter(centerEnd);
                  anim.setEasing(HDImageViewer.Ease.OUT_QUAD);

                  anim.start();
                } else {
                  this.controller?.pan(
                    vp2px(event.offsetX - this.startOffsetX), vp2px(event.offsetY - this.startOffsetY));
                }
              }),
            TapGesture({ count: 2, fingers: 1, distanceThreshold: 10})
              .onAction((event:GestureEvent) => {
                if (!event) {
                  return;
                }
                let fingerInfo: FingerInfo[] = event.fingerList;
                if (!!fingerInfo && fingerInfo.length > 0) {
                  this.controller?.doubleClickZoom(vp2px(fingerInfo[0].localX), vp2px(fingerInfo[0].localY));
                }
              })
          ).onCancel(() => {
            this.log('Parallel gesture canceled');
          })
        )
    }
    .clip(true)
  }
}

namespace HDImageViewer {
  export class  ImageResourceInfo {
    src: PixelMap | ResourceStr | DrawableDescriptor = '';
    previewSrc?: PixelMap | ResourceStr;
  }

  export class StateChangedListener {
    onScaleChanged(newScale: number): void {};
    onCenterChanged(center: common2D.Point): void {};
  }

  export class ImageEventListener {
    onImageReady(): void {};
    onImageLoaded(): void {};
    onImageLoadError(error: string): void {};
    onTileLoadError(error: string): void {};
    onPreviewImageReady(): void {};
    onPreviewImageReleased(): void {};
    onPreviewImageLoadError(error: string): void {};
  }

  export class AnimEventListener {
    onComplete(): void {};
    onInterruptedByUser(): void {};
    onInterruptedByNewAnim(): void {};
    onStartError(error: string): void {};
  }

  export enum PanLimit {
    INSIDE,
    OUTSIDE,
    CENTER
  }

  export enum Ease {
    IN_OUT_QUAD,
    OUT_QUAD
  }

  export enum Orientation {
    ORIENTATION_0,
    ORIENTATION_90,
    ORIENTATION_180,
    ORIENTATION_270,
    ORIENTATION_FLIP_H,
    ORIENTATION_FLIP_V,
    ORIENTATION_FLIP_H_270,
    ORIENTATION_FLIP_H_90,
    ORIENTATION_UES_EXIF
  }

  enum ImageFlipType {
    NONE,
    HORIZONTAL,
    VERTICAL
  }

  enum ImageRotation {
    ROTATION_0,
    ROTATION_90,
    ROTATION_180,
    ROTATION_270
  }

  class Tile {
    sRect: common2D.Rect = {left: 0, top: 0, right: 0, bottom: 0};
    sampleSize: number = 0;
    pixelMap: image.PixelMap | null = null;
    loading: boolean = false;
    visible: boolean = false;
    vRect: common2D.Rect = {left: 0, top: 0, right: 0, bottom: 0};
    fileSRect: common2D.Rect = {left: 0, top: 0, right: 0, bottom: 0};
    name: string = "";
  }

  class Anim {
    scaleStart: number = 0;
    scaleEnd: number = 0;
    sCenterEnd: common2D.Point = {x: 0, y: 0}; // Focus on the picture
    userFocus: boolean = false;
    // During animation, the sCenterEnd should be shifted from vFocusStart to vFocusEnd
    vFocusStart: common2D.Point = {x: 0, y: 0};
    vFocusEnd: common2D.Point = {x: 0, y: 0};
    duration: number = 500;
    time: number = 0;
    interruptable: boolean = true;
    easing: number = Ease.IN_OUT_QUAD;
    started: boolean = false;
    valid: boolean = false;
    listener: AnimEventListener | null = null;

    reset() {
      this.scaleStart = 0;
      this.scaleEnd = 0;
      this.sCenterEnd.x = 0;
      this.sCenterEnd.y = 0;
      this.userFocus = false;
      this.vFocusStart.x = 0;
      this.vFocusStart.y = 0;
      this.vFocusEnd.x = 0;
      this.vFocusEnd.y = 0;
      this.duration = 500;
      this.time = 0;
      this.interruptable = true;
      this.easing = Ease.IN_OUT_QUAD;
      this.started = false;
      this.valid = false;
      this.listener = null;
    }

    public ease(time: number, from: number, change: number, duration: number): number {
      if (time >= duration) {
        return from + change;
      }
      if (this.easing == Ease.IN_OUT_QUAD) {
        let timeF = time / (duration / 2);
        if (timeF < 1) {
          return (change / 2 * timeF *timeF) + from;
        } else {
          timeF--;
          return (-change / 2) * (timeF * (timeF - 2) - 1) + from;
        }
      } else {
        let progress = time / duration;
        return - change * progress * (progress - 2) + from;
      }
    }
  }

  export class AnimBuilder {
    scaleEnd: number = 0;
    sCenterEnd: common2D.Point = {x: -1, y: -1};
    userFocus: boolean = false;
    vFocusEnd: common2D.Point = {x: -1, y: -1};
    duration: number = 500;
    interruptable: boolean = true;
    easing: number = Ease.IN_OUT_QUAD;
    listener: AnimEventListener | null = null;

    anim: Anim | null = null;
    modifier: HDDrawModifier | null = null;

    constructor(anim: Anim, modifier: HDDrawModifier | null) {
      this.anim = anim;
      this.modifier = modifier;
    }

    public setScale(scale: number): void {
      this.scaleEnd = scale;
    }

    public setCenter(center: common2D.Point): void {
      this.sCenterEnd = center;
    }

    public setFocus(focus: common2D.Point): void {
      this.userFocus = true;
      this.vFocusEnd.x = focus.x;
      this.vFocusEnd.y = focus.y;
    }

    public setDuration(duration: number): void {
      this.duration = duration;
    }

    public setInterruptable(interruptable: boolean): void {
      this.interruptable = interruptable;
    }

    public setEasing(easing: number): void {
      this.easing = easing;
    }

    public setEvenListener(listener: AnimEventListener): void {
      this.listener = listener;
    }

    public start(): boolean {
      if (this.anim == null) {
        this.listener?.onStartError(
          "The current animated object is abnormal, please get the animated object again");
        return false;
      }

      if (this.anim.valid) {
        if (!this.anim.interruptable) {
          this.listener?.onStartError("The current animation cannot be interrupted, please try again later");
          return false;
        }
        this.anim.valid = false;
        this.anim.listener?.onInterruptedByNewAnim();
      }

      this.anim.scaleEnd = this.scaleEnd;
      this.anim.sCenterEnd = this.sCenterEnd;
      this.anim.userFocus = this.userFocus;
      this.anim.vFocusEnd = this.vFocusEnd;
      this.anim.duration = this.duration;
      this.anim.interruptable = this.interruptable;
      this.anim.easing = this.easing;
      this.anim.listener = this.listener;
      this.anim.time = systemDateTime.getUptime(systemDateTime.TimeType.ACTIVE, false);
      this.anim.started = false;
      this.anim.valid = true;

      this.modifier?.doInvalidate();
      return true;
    }
  }

  @ObservedV2
  export class Controller {
    // Display status
    private offsetX: number = 0; // The offset of the upper-left corner of the image relative to the view
    private offsetY: number = 0;
    private scale: number = 1.0; // The multiple of the image scale
    private viewHeight : number = 0; // The current component height
    private viewWidth : number = 0; // The current component width
    private sRect: common2D.Rect = {left:0, right:0, top:0, bottom:0}; // The viewport of the current image
    private ready: boolean = false; // The picture is ready, and the next frame will be drawn
    private imageLoaded: boolean = false; // Pictures have started to load and display
    private sInfoReady: boolean = false; // Obtain the width and height of the original image and the rotation angle

    private previewScale: number = 1.0;
    private previewOffsetX: number = 0;
    private previewOffsetY: number = 0;
    private previewSrcRect: common2D.Rect = {left:0, right:0, top:0, bottom:0};
    private previewState: number = 0;
    private readonly  STATE_NULL: number = 0x0;
    private readonly  GET_SIZE: number = 0x1;
    private readonly  GET_ORIENTATION: number = 0x2;
    private readonly  GET_PIXEL: number = 0x4;
    private readonly  STATE_ALL: number = 0x7;

    // source
    private src: PixelMap | ResourceStr | DrawableDescriptor | undefined;
    private previewSrc: PixelMap | ResourceStr | undefined;
    private pixelMap : image.PixelMap | null = null;
    private previewPixelMap : image.PixelMap | null = null;
    private imageData: ArrayBuffer | null = null;
    modifier: HDDrawModifier | null = null;
    panOption: PanGestureOptions = new PanGestureOptions({fingers: 1, direction: PanDirection.None})

    // Original image information
    private sWidth: number = 0; // Doesn't care about the angle of rotation
    private sHeight: number = 0;
    private sOrientation: number = Orientation.ORIENTATION_0;
    private previewSrcWidth: number = 0;
    private previewSrcHeight: number = 0;
    private sPreviewOrientation: number = Orientation.ORIENTATION_0;

    // Configuration information
    private zoomEnabled: boolean = true;
    private zoomDuration: number = 1000;
    private doubleClickEnable: boolean = true;
    private doubleTapZoomScale: number = 1;
    private zoomUseAnim: boolean = true;
    private maxScale: number = 4.0;
    private minScale: number = 0;

    private panEnabled: boolean = true;
    private panLimitType: number = PanLimit.INSIDE;

    private orientation: number = Orientation.ORIENTATION_UES_EXIF;
    private previewOrientation: number = Orientation.ORIENTATION_UES_EXIF;
    private tileBackgroundColor: common2D.Color = { alpha: 0, red: 0, green: 0, blue: 0};
    private anim: Anim = new Anim();
    private eagerLoadingEnabled: boolean = true;
    private debug: boolean = false;

    // Event callbacks
    private imageEventListener: ImageEventListener | null = null;
    private stateChangedListener: StateChangedListener | null = null;

    // State variables for internal controls
    private fullImageScale: number = 0; // The scale when the image fills the view is also the scale of the basemap
    private fullImageSampleSize: number = 0;
    private defaultImageScale: number = 0; // Limited by the minScale-maxScale range
    private offsetXDefault: number = 0;
    private offsetYDefault: number = 0;
    // The amount of translation that can also be moved around
    private panRemaining: common2D.Rect = {left:0, right:0, top:0, bottom:0};
    private limitSize = 2048; // If the image is smaller than limitSize*limitSize, region decoding will not be enabled
    private usingTiles = true; // Enable chunk decoding

    private tileMap: Map<number, Tile[]> | null = null;
    private fullImageTile: Tile = new Tile();
    private loadingFullImageTile: boolean = false;
    private loadingSampleSize: number = 0;
    private fullImageTileRotation: number = ImageRotation.ROTATION_0;
    private fullImageTileFlip: ImageFlipType = ImageFlipType.NONE;

    private decodingCnt: number = 0;
    private tilesQueueToDecode: Tile[] = [];
    private readonly maxDecodingCnt: number = 4;

    private static readonly taskBase: number = 10000;
    private static globalTaskId: number = Controller.taskBase;
    private taskId: number = Controller.taskBase;
    private taskCount: number = 0;

    constructor() {
      this.taskId = Controller.globalTaskId;
      Controller.globalTaskId += Controller.taskBase;
      this.info("create");
    }

    private getCallerInfo(): string {
      const stack = new Error().stack;
      if (stack) {
        const stackLines = stack.split('\n');
        if (stackLines.length >= 3) {
          let callerLine = stackLines[2].trim();
          const match = callerLine.match(/\(?(.+):(\d+):\d+\)?$/);
          if (match) {
            return `${this.taskId}(${match[0].split(' ')[1]}:${match[2]})`;
          }
        }
      }
      return `${this.taskId}`;
    }

    private log(message: string): void {
      if (this.debug) {
        hilog.debug(DOMAIN, TAG, this.getCallerInfo() + message);
      }
    }

    private info(message: string): void {
      hilog.info(DOMAIN, TAG, this.getCallerInfo() + message);
    }

    private error(message: string): void {
      hilog.error(DOMAIN, TAG, this.getCallerInfo() + message);
    }

    private ReadyToDraw(): boolean
    {
      if (!this.sInfoReady || this.viewWidth == 0 || this.viewHeight == 0) {
        this.log('The resources or views are not ready yet');
        return false;
      }

      if (this.usingTiles) {
        if (this.tileMap == null) {
          this.log('tileMap is null')
          return false;
        }
      } else {
        if (this.pixelMap == null) {
          this.log('pixelMap is null')
          return false;
        }
      }

      return true;
    }

    private onDrawPixelMap(context: DrawContext): void {
      let vRect: common2D.Rect = {left:0, right:0, top:0, bottom:0};
      let fRect: common2D.Rect = {left:0, right:0, top:0, bottom:0};
      let rRect: common2D.Rect = {left:0, right:0, top:0, bottom:0};
      this.sourceToFileRect(this.sRect, fRect)
      this.sourceToViewRect(this.sRect, vRect, this.scale, this.offsetX, this.offsetY)
      this.viewToRotateRect(vRect, rRect, this.getAppliedRotation());

      let orientation = 90 * this.getAppliedRotation();
      context.canvas.rotate(orientation, 0, 0); // Rotate the canvas counterclockwise
      context.canvas.drawImageRectWithSrc(this.pixelMap, fRect, rRect);
      context.canvas.rotate(360 - orientation, 0, 0);
      if (!this.imageLoaded) {
        this.imageLoaded = true;
        this.imageEventListener?.onImageLoaded();
        this.info("onImageLoaded by pixelmap");
      }
    }

    public onDraw(context: DrawContext): void
    {
      // Paint the background color
      context.canvas.drawColor(this.tileBackgroundColor)

      // Draw a preview
      if (this.isPreviewImageReady() && !this.isReady()) {
        this.onDrawPreview(context);
        return;
      }

      if (this.ReadyToDraw() == false) {
        return;
      }

      // Animation calculations are performed on demand
      this.onAnimUpdate();

      if (this.usingTiles == false) {
        this.onDrawPixelMap(context);
      } else {
        // Region decoding drawing
        let sampleSize = this.calculateInSampleSize(this.scale);
        if (this.needDrawBaseLayer(sampleSize)) {
          this.drawBaseLayer(context);
        }
        if (sampleSize < this.fullImageSampleSize) {
          this.drawOneSampleSize(context, sampleSize)
        }
      }

      // The animation triggers the next frame
      if (this.anim.valid) {
        this.modifier?.doInvalidate();
      }
    }

    private onDrawPreview(context: DrawContext): void
    {
      this.updatePreviewSrcRectScaleOffset();
      let fRect: common2D.Rect = {left:0, right:this.previewSrcWidth, top:0, bottom:this.previewSrcHeight};
      let vRect: common2D.Rect = {left:0, right:0, top:0, bottom:0};
      let rRect: common2D.Rect = {left:0, right:0, top:0, bottom:0};
      this.sourceToViewRect(this.previewSrcRect, vRect, this.previewScale, this.previewOffsetX, this.previewOffsetY)
      this.viewToRotateRect(vRect, rRect, this.getAppliedRotation(true));

      this.log(`PreviewOrientation: ` + this.previewOrientation +
        ` fRect(${fRect.left}, ${fRect.top}, ${fRect.right}, ${fRect.bottom}) ` +
        ` rRect(${rRect.left}, ${rRect.top}, ${rRect.right}, ${rRect.bottom}) ` +
        ` vRect(${vRect.left}, ${vRect.top}, ${vRect.right}, ${vRect.bottom})`)

      let orientation = 90 * this.getAppliedRotation(true);
      context.canvas.rotate(orientation, 0, 0); // Rotate the canvas counterclockwise
      context.canvas.drawImageRectWithSrc(this.previewPixelMap, fRect, rRect);
      context.canvas.rotate(360 - orientation, 0, 0); // Rotate the canvas back
    }

    private onAnimStart(anim: Anim): void {
      anim.scaleStart = this.scale;
      if (anim.scaleEnd > 0) {
        anim.scaleEnd = this.fitScale(anim.scaleEnd);
      } else {
        anim.scaleEnd = this.scale;
      }

      // At the beginning of the animation, the focus of the picture corresponds to the position of the view
      anim.vFocusStart.x = this.sourceToViewX(anim.sCenterEnd.x, this.scale, this.offsetX);
      anim.vFocusStart.y = this.sourceToViewY(anim.sCenterEnd.y, this.scale, this.offsetY);
      if (!anim.userFocus) {
        // At the end of the animation, the picture focus corresponds to the position of the view
        anim.vFocusEnd.x = this.viewWidth / 2;
        anim.vFocusEnd.y = this.viewHeight / 2;
      }

      // Make sure that the end point of the animation meets the panlimit requirements
      let x = anim.vFocusEnd.x - anim.sCenterEnd.x * anim.scaleEnd;
      let y = anim.vFocusEnd.y - anim.sCenterEnd.y * anim.scaleEnd;
      let point = this.fitOffset(x, y, anim.scaleEnd, this.panLimitType);
      anim.vFocusEnd.x = (anim.sCenterEnd.x) * anim.scaleEnd + point.x;
      anim.vFocusEnd.y = (anim.sCenterEnd.y) * anim.scaleEnd + point.y;
    }

    private onAnimUpdate(): void {
      if (!this.anim.valid) {
        return;
      }

      if (!this.anim.started) {
        this.onAnimStart(this.anim);
        this.anim.started = true;
      }

      let anim = this.anim;
      let scaleElapsed = systemDateTime.getUptime(systemDateTime.TimeType.ACTIVE, false) - anim.time;
      anim.valid = scaleElapsed < anim.duration;
      scaleElapsed = Math.min(scaleElapsed, anim.duration);

      let scale = anim.scaleEnd;
      if (anim.valid) {
        scale = anim.ease(scaleElapsed, anim.scaleStart, anim.scaleEnd - anim.scaleStart, anim.duration);
      }

      let viewX = anim.vFocusEnd.x;
      let viewY = anim.vFocusEnd.y;
      if (anim.valid) {
        viewX = anim.ease(scaleElapsed, anim.vFocusStart.x, anim.vFocusEnd.x - anim.vFocusStart.x, anim.duration);
        viewY = anim.ease(scaleElapsed, anim.vFocusStart.y, anim.vFocusEnd.y - anim.vFocusStart.y, anim.duration);
      }
      let offSetX = viewX - anim.sCenterEnd.x * scale;
      let offSetY = viewY - anim.sCenterEnd.y * scale;

      // When scaling with two fingers, the scale is allowed to exceed the maximum and minimum value,
      // and the scale value will be restored to the threshold by animation.
      // In this process, the scale value exceeds the threshold, so the updateScale interface is not used here.
      this.scale = scale;
      this.updateOffset(offSetX, offSetY, PanLimit.OUTSIDE);
      // The decoding task is not triggered during the animation
      this.refreshRequiredTiles(!anim.valid);

      if (!anim.valid) {
        // At the end of the animation, make sure that the scale and offset are within reason
        this.updateScale(scale);
        this.fitOffset(offSetX, offSetY, this.scale, this.panLimitType);
        this.setPanOption();
        anim.listener?.onComplete();
      }
    }

    private onAnimInterruptable(): boolean {
      if (!this.anim.valid) {
        return true;
      }

      if (this.anim.interruptable) {
        this.log("onInterruptedByUser");
        this.anim.listener?.onInterruptedByUser();
        this.anim.reset();
        return true;
      }

      this.log("The animation cannot be interrupted");
      return false;
    }

    private drawBaseLayer(context: DrawContext): void {
      let drawTile: Tile | null = null;
      let grid = this.tileMap?.get(this.fullImageSampleSize) ?? null;
      if (grid != null && grid.length == 1 && grid[0].pixelMap != null) {
        drawTile = grid[0];
      } else if (this.fullImageTile.pixelMap != null) {
        drawTile = this.fullImageTile;
      } else {
        this.log("The baseLayer has not yet been decoded");
        return;
      }

      this.sourceToViewRect(drawTile.sRect, drawTile.vRect, this.scale, this.offsetX, this.offsetY);

      let stime: number = 0;
      if (this.debug) {
        const pen = new drawing.Pen();
        pen.setStrokeWidth(10);
        pen.setColor({alpha: 255, red: 255, green: 0, blue: 0});
        context.canvas.attachPen(pen);
        context.canvas.drawRect(drawTile.vRect);
        stime = systemDateTime.getUptime(systemDateTime.TimeType.ACTIVE, false);
      }
      context.canvas.drawImageRect(drawTile.pixelMap, drawTile.vRect);

      if (this.debug) {
        context.canvas.detachPen();
        let etime = systemDateTime.getUptime(systemDateTime.TimeType.ACTIVE, false);
        this.log(`drawBaseLayer ${etime-stime}ms, ${drawTile.name}: sample{${drawTile.sampleSize} ` +
          `sRect(${drawTile.sRect.left}, ${drawTile.sRect.top}, ${drawTile.sRect.right}, ${drawTile.sRect.bottom}) to` +
          ` vRect(${drawTile.vRect.left}, ${drawTile.vRect.top}, ${drawTile.vRect.right}, ${drawTile.vRect.bottom})`)
      }

      if (!this.imageLoaded) {
        this.imageLoaded = true;
        this.imageEventListener?.onImageLoaded();
        this.info("onImageLoaded by drawBaseLayer");
      }
    }

    private drawOneSampleSize(context: DrawContext, sampleSize: number): void {
      let grid = this.tileMap?.get(sampleSize) ?? null;
      if (grid == null) {
        this.error("failed to get tile, sampleSize:" + sampleSize);
        return;
      }

      if (this.debug) {
        const pen = new drawing.Pen();
        pen.setStrokeWidth(10);
        pen.setColor({alpha: 255, red: 255, green: 0, blue: 0});
        context.canvas.attachPen(pen);
      }
      let stime: number = 0;
      for (const tile of grid) {
        if (!tile.visible) {
          continue;
        }
        if (tile.loading || tile.pixelMap == null) {
          this.log(`tile ${tile.name} is loading or bitmap is null, skip to draw`);
          continue;
        }
        this.sourceToViewRect(tile.sRect, tile.vRect, this.scale, this.offsetX, this.offsetY);
        if (this.debug) {
          context.canvas.drawRect(tile.vRect);
          stime = systemDateTime.getUptime(systemDateTime.TimeType.ACTIVE, false);
        }
        context.canvas.drawImageRect(tile.pixelMap, tile.vRect);
        if (this.debug) {
          let etime = systemDateTime.getUptime(systemDateTime.TimeType.ACTIVE, false);
          this.log(`drawOneSampleSize ${etime-stime}ms, ${tile.name}: sample{${tile.sampleSize} ` +
            `sRect(${tile.sRect.left}, ${tile.sRect.top}, ${tile.sRect.right}, ${tile.sRect.bottom}) to ` +
            `vRect(${tile.vRect.left}, ${tile.vRect.top}, ${tile.vRect.right}, ${tile.vRect.bottom})`)
        }

        if (!this.imageLoaded) {
          this.imageLoaded = true;
          this.imageEventListener?.onImageLoaded();
          this.info("onImageLoaded by drawOneSampleSize");
        }
      }
      if (this.debug) {
        context.canvas.detachPen();
      }
    }

    private needDrawBaseLayer(sampleSize: number): boolean {
      if (sampleSize == this.fullImageSampleSize) {
        return true;
      }

      if (!this.tileMap) {
        return true;
      }

      let tiles = this.tileMap?.get(sampleSize);
      if (tiles == undefined) {
        return true;
      }

      for (const tile of tiles) {
        if (tile.visible && (tile.loading || tile.pixelMap == null)) {
          this.log(`tile not ready: ${tile.name}`);
          return true;
        }
      }
      return false;
    }

    private onFullImageTileLoad(tile: Tile, pixelMap: PixelMap): void {
      // Store the global tile
      if (this.fullImageTile.pixelMap) {
        this.fullImageTile.pixelMap.release();
      }
      this.fullImageTile.pixelMap = pixelMap;
      this.fullImageTile.sRect = tile.sRect;
      this.fullImageTile.fileSRect = tile.fileSRect;
      this.fullImageTile.name = tile.name;
      this.fullImageTile.sampleSize = tile.sampleSize;

      this.loadingFullImageTile = false;
      this.fullImageTileRotation = this.getAppliedRotation();
      this.fullImageTileFlip = this.getAppliedFlip();

      let grid = this.tileMap?.get(this.fullImageSampleSize) ?? null;
      if (grid != null && grid.length == 1 && grid[0].pixelMap == null && grid[0].sampleSize == tile.sampleSize) {
        grid[0] = tile;
      }

      // Release the preview image resource
      if (this.previewPixelMap != null) {
        this.previewPixelMap.release();
        this.previewPixelMap = null;
        this.imageEventListener?.onPreviewImageReleased();
      }

      // Notification of the ready event
      if (!this.ready) {
        this.ready = true;
        this.imageEventListener?.onImageReady();
        this.info("onImageReady by fullImageTileLoad");
        hiTraceMeter.finishTrace("HDImageViewer init", this.taskId);
      }
    }

    private tileLoadTask(tile: Tile): void {
      let starttime = 0;
      let taskCount = (this.taskCount++) % Controller.taskBase;
      if (this.debug) {
        this.log(`tileLoadTask for tile ${tile.name}`);
        starttime = systemDateTime.getUptime(systemDateTime.TimeType.ACTIVE, false);
        hiTraceMeter.startTrace("HDImageViewer decoder", this.taskId + taskCount);
      }
      tile.loading = true;
      this.decodingCnt += 1;

      if (tile.sampleSize == this.fullImageSampleSize) {
        this.loadingFullImageTile = true;
        this.loadingSampleSize = tile.sampleSize;
      }

      let w = tile.fileSRect.right - tile.fileSRect.left
      let h = tile.fileSRect.bottom - tile.fileSRect.top
      let decodingOptions : image.DecodingOptions = {
        editable: false,
        desiredPixelFormat: image.PixelMapFormat.RGB_565,
        desiredRegion:  {x: Math.floor(tile.fileSRect.left), y: Math.floor(tile.fileSRect.top), size: {width: Math.floor(w), height: Math.floor(h)}},
        desiredSize: {width: Math.floor(w / tile.sampleSize), height: Math.floor(h / tile.sampleSize)},
        // cropAndScaleStrategy: image.CropAndScaleStrategy.CROP_FIRST
      }

      let imageSource: image.ImageSource;
      if (this.imageData) {
        imageSource = image.createImageSource(this.imageData);
      } else {
        imageSource = image.createImageSource(this.src as string);
      }

      imageSource?.createPixelMap(decodingOptions)
        .then((pixelMap: image.PixelMap) => {
          let s = pixelMap.getPixelBytesNumber()
          this.log(`pixelMap size is ${s}, and release ${imageSource}`);
          imageSource.release()
          let flip = this.getAppliedFlip();
          if (flip == ImageFlipType.HORIZONTAL) {
            pixelMap.flipSync(true, false)
          } else if (flip == ImageFlipType.VERTICAL) {
            pixelMap.flipSync(false, true)
          }

          // Rotate to the correct drawing direction
          if (this.getAppliedRotation() != ImageRotation.ROTATION_0) {
            pixelMap.rotateSync(this.getAppliedRotation()*90);
          }

          if (tile.sampleSize == this.fullImageSampleSize) {
            this.onFullImageTileLoad(tile, pixelMap);
          }
          tile.loading = false;
          tile.pixelMap = pixelMap;

          // Wake up other decoding tasks
          this.decodingCnt -= 1;
          this.checkTilesQueuetoDecode();

          // debug
          if (this.debug) {
            hiTraceMeter.finishTrace("HDImageViewer decoder", this.taskId + taskCount);
            let endtime = systemDateTime.getUptime(systemDateTime.TimeType.ACTIVE, false);
            this.log(`tileLoadTask finish for tile ${tile.name} cost ${endtime - starttime}`);
          }

          // Decide whether or not to trigger drawing based on the latest layout
          let sampleSize = this.calculateInSampleSize(this.scale);
          if ((tile.sampleSize == sampleSize && this.tileVisible(tile, this.sRect)) ||
            (tile.sampleSize == this.fullImageSampleSize)) {
            this.modifier?.doInvalidate();
          } else {
            // During decoding, if tile becomes invisible due to view changes, skip refresh and just free memory.
            this.refreshRequiredTiles(false);
          }
        })
        .catch((err : BusinessError) => {
          this.error("Failed to getPixelsAsync, error = " + err.message)
          // Wake up other decoding tasks
          this.decodingCnt -= 1;
          this.checkTilesQueuetoDecode();
        });
    }

    private newTileLoadTask(tile: Tile): void {
      tile.loading = true;
      if (this.decodingCnt < this.maxDecodingCnt) {
        this.tileLoadTask(tile);
        return;
      }
      this.tilesQueueToDecode.push(tile);
    }

    private checkTilesQueuetoDecode() {
      let sampleSize = this.calculateInSampleSize(this.scale);
      while (this.tilesQueueToDecode.length > 0 && this.decodingCnt < this.maxDecodingCnt) {
        const tile = this.tilesQueueToDecode.pop() as Tile;
        if ((tile.sampleSize == sampleSize && this.tileVisible(tile, this.sRect)) ||
          (tile.sampleSize == this.fullImageSampleSize)) {
          // The tile is still visible, triggering the decoding task
          this.tileLoadTask(tile);
        } else {
          // The tile is no longer visible and stops decoding
          tile.loading = false;
          tile.visible = false;
        }
      }
    }

    private calculateInSampleSize(scale: number): number {
      let inSampleSize =  Math.ceil(1 / scale);
      let power = 1;
      while (power * 2 < inSampleSize) {
        power *= 2;
      }
      return power;
    }

    private initialiseBaseLayer(): void {
      let baseGrid = this.tileMap?.get(this.fullImageSampleSize) ?? null;
      if (baseGrid == null || baseGrid.length != 1) {
        this.error(`failed to get tile, full Image Sample Size: ${this.fullImageSampleSize}`);
        return;
      }

      if (this.fullImageTile.pixelMap != null && this.fullImageTile.sampleSize == this.fullImageSampleSize) {
        baseGrid[0].pixelMap = this.fullImageTile.pixelMap;
        baseGrid[0].sRect = {left:0, top: 0, right: this.getSrcWidth(), bottom: this.getSrcHeight()}
        baseGrid[0].fileSRect = this.fullImageTile.fileSRect;
        baseGrid[0].name = this.fullImageTile.name;
        baseGrid[0].sampleSize = this.fullImageTile.sampleSize;
        baseGrid[0].loading = false;
        baseGrid[0].visible = true;

        let rotation = this.getAppliedRotation();
        if (rotation != this.fullImageTileRotation) {
          let num = ((rotation + 4 - this.fullImageTileRotation) * 90) % 360;
          baseGrid[0].pixelMap.rotateSync(num);
          this.log("Rotate the baselayer, ori:" + this.fullImageTileRotation +
            " now：" + rotation + " change:" + num);
          this.fullImageTileRotation = rotation;
        }

        this.modifier?.doInvalidate();
        this.log("Reuse the previous global tile");
      } else if (!this.loadingFullImageTile || this.loadingSampleSize != baseGrid[0].sampleSize) {
        this.newTileLoadTask(baseGrid[0]);
        this.log("A new decoded global tile is required");
      } else {
        baseGrid[0].loading = true;
        this.log("The global tile is being decoded");
      }
    }

    private initialiseTileMap(): void {
      this.tileMap = new Map<number, Tile[]>();
      let sampleSize = this.fullImageSampleSize;
      let xTiles = 1;
      let yTiles = 1;
      let srcWidth = this.getSrcWidth();
      let srcHeight = this.getSrcHeight();
      while (true) {
        let sTileWidth = srcWidth/xTiles;
        let sTileHeight = srcHeight/yTiles;
        let subTileWidth = sTileWidth/sampleSize;
        let subTileHeight = sTileHeight/sampleSize;
        while ((subTileWidth > this.viewWidth * 1.25 && sampleSize < this.fullImageSampleSize)) {
          xTiles += 1;
          sTileWidth = srcWidth/xTiles;
          subTileWidth = sTileWidth/sampleSize;
        }
        while ((subTileHeight > this.viewHeight * 1.25 && sampleSize < this.fullImageSampleSize)) {
          yTiles += 1;
          sTileHeight = srcHeight/yTiles;
          subTileHeight = sTileHeight/sampleSize;
        }
        this.log(`do tile for sample ${sampleSize}: ${xTiles} * ${yTiles}`)
        let tileGrid: Tile[] = [];
        for (let x = 0; x < xTiles; x++) {
          for (let y = 0; y < yTiles; y++) {
            let tile = new Tile();
            tile.sampleSize = sampleSize;
            tile.visible = sampleSize == this.fullImageSampleSize;
            tile.sRect = {
              left: x * sTileWidth,
              top: y * sTileHeight,
              right: x == xTiles - 1 ? srcWidth : (x + 1) * sTileWidth,
              bottom: y == yTiles - 1 ? srcHeight : (y + 1) * sTileHeight};
            tile.vRect = {left: 0, top: 0, right: 0, bottom: 0};
            this.sourceToFileRect(tile.sRect, tile.fileSRect)
            tile.name = x.toString() + "*" + y.toString() + " in " + xTiles.toString() + "*" +yTiles.toString() + " sample-" + tile.sampleSize;
            tileGrid.push(tile);
          }
        }
        this.tileMap.set(sampleSize, tileGrid);
        if (sampleSize == 1) {
          break;
        } else {
          sampleSize /= 2;
        }
      }
      this.showTileMap();
    }

    private refreshRequiredTiles(load: boolean): void {
      this.sRect.left = this.viewToSourceX(0);
      this.sRect.right = this.viewToSourceX(this.viewWidth);
      this.sRect.top = this.viewToSourceY(0);
      this.sRect.bottom = this.viewToSourceY(this.viewHeight);

      if (!this.usingTiles) {
        return;
      }

      if (this.tileMap == null) {
        this.error("tileMap is null");
        return;
      }

      let sampleSize = this.calculateInSampleSize(this.scale);
      this.log(`scale ${this.scale}, samplesize ${sampleSize}`);

      // Release the unneeded tile first, and then decode the new tile to reduce the memory usage
      for (const tileMapEntry of this.tileMap.entries()) {
        for (const tile of tileMapEntry[1]) {
          // The tile of the whole image is not released and is stored consistently, as a basemap
          if (tile.sampleSize == this.fullImageSampleSize) {
            break;
          }
          if ((tile.sampleSize != sampleSize) || (!this.tileVisible(tile, this.sRect))) {
            tile.visible = false;
            if (tile.pixelMap != null) {
              this.log(`destroy tile ${tile.name} because samplesize is changed`);
              let pixelMap: image.PixelMap | null = tile.pixelMap;
              tile.pixelMap = null;
              pixelMap.release().then(() => {
                this.log(`destroyPixelsAsync finish for tile ${tile.name}`);
              });
            }
          }
        }
      }
      for (const tileMapEntry of this.tileMap.entries()) {
        for (const tile of tileMapEntry[1]) {
          if (tile.sampleSize != sampleSize) {
            break;
          }
          if (this.tileVisible(tile, this.sRect)) {
            tile.visible = true;
            if (!tile.loading && tile.pixelMap == null && load) {
              this.newTileLoadTask(tile);
            }
          }
        }
      }
    }

    private resetTileMap(resetImage: boolean): void {
      if (this.tileMap == null) {
        return;
      }

      let baseGrid = this.tileMap?.get(this.fullImageSampleSize) ?? null;
      if (baseGrid != null && baseGrid.length == 1 && !resetImage) {
        baseGrid[0].pixelMap = null;
      }

      for (const tileMapEntry of this.tileMap.entries()) {
        for (const tile of tileMapEntry[1]) {
          if (tile.pixelMap != null) {
            tile.pixelMap.release();
            tile.pixelMap = null;
          }
        }
      }
      this.tileMap = null;
    }

    private previewReset(): void {
      this.previewSrc = undefined;
      this.previewPixelMap = null;
      this.previewScale = 0;
      this.previewSrcWidth = 0;
      this.previewSrcHeight = 0;
      this.previewSrcRect.left = 0;
      this.previewSrcRect.right = 0;
      this.previewSrcRect.top = 0;
      this.previewSrcRect.bottom = 0;
      this.previewState = this.STATE_NULL;
    }

    private reset(resetImage: boolean): void {
      // Display status reset
      this.offsetX = 0;
      this.offsetY = 0;
      this.scale = 0;
      this.sRect.left = 0;
      this.sRect.right = 0;
      this.sRect.top = 0;
      this.sRect.bottom = 0;
      this.anim.reset();
      this.resetTileMap(resetImage);

      // State variables for internal controls
      this.fullImageScale = 0.0;
      this.fullImageSampleSize = 0;
      this.defaultImageScale = 0.0;
      while (this.tilesQueueToDecode.length > 0) {
        this.tilesQueueToDecode.pop();
      }
      this.decodingCnt = 0;

      if (resetImage) {
        this.previewReset();
        // Display status reset
        this.ready = false;
        this.imageLoaded = false;
        this.sInfoReady = false;

        // source reset
        this.src = undefined;
        this.pixelMap = null;
        this.imageData = null;

        // Original image information
        this.sWidth = 0;
        this.sHeight = 0;
        this.sOrientation = Orientation.ORIENTATION_0;

        // State variables for internal controls
        this.usingTiles = true;
        this.loadingFullImageTile = false;
        if (this.fullImageTile.pixelMap) {
          this.fullImageTile.pixelMap.release();
        }
        this.fullImageTile = new Tile();
        this.fullImageTileRotation = ImageRotation.ROTATION_0;
        this.fullImageTileFlip = ImageFlipType.NONE;
      }
    }

    private tileVisible(tile: Tile, sRect:common2D.Rect): boolean {
      return !(sRect.left > tile.sRect.right || tile.sRect.left > sRect.right ||
        sRect.top > tile.sRect.bottom || tile.sRect.top > sRect.bottom);
    }

    // Convert screen to source x coordinate
    private viewToSourceX(vx: number): number {
      return Math.min(Math.max(0, (vx - this.offsetX)) / this.scale, this.getSrcWidth());
    }

    // Convert screen to source y coordinate.
    private viewToSourceY(vy: number): number {
      return Math.min(Math.max(0, (vy - this.offsetY)) / this.scale, this.getSrcHeight());
    }

    private sourceToViewRect(
      sRect: common2D.Rect, vTarget: common2D.Rect, scale: number, offsetX: number, offsetY: number): void {
      vTarget.left = Math.floor(this.sourceToViewX(sRect.left, scale, offsetX));
      vTarget.top = Math.floor(this.sourceToViewY(sRect.top, scale, offsetY));
      vTarget.right = Math.floor(this.sourceToViewX(sRect.right, scale, offsetX));
      vTarget.bottom = Math.floor(this.sourceToViewY(sRect.bottom, scale, offsetY));
    }

    private sourceToViewX(sx: number, scale: number, offsetX: number): number {
      return (sx * scale) + offsetX;
    }

    private sourceToViewY(sy: number, scale: number, offsetY: number): number {
      return (sy * scale) + offsetY;
    }

    private sourceToFileRect(srcRect: common2D.Rect, fileRect:common2D.Rect, isPreview: boolean = false): void {
      let currentWidth = isPreview ? this.previewSrcWidth : this.sWidth;
      let currentHeight = isPreview ? this.previewSrcHeight : this.sHeight;
      // Rotate clockwise, fileRect on the counterclockwise side of srcRect
      let rotation= this.getAppliedRotation();
      if (rotation == ImageRotation.ROTATION_0) {
        fileRect.left = srcRect.left;
        fileRect.right = srcRect.right;
        fileRect.top = srcRect.top;
        fileRect.bottom = srcRect.bottom;
      } else if (rotation == ImageRotation.ROTATION_90) {
        fileRect.left = srcRect.top;
        fileRect.top = currentHeight - srcRect.right;
        fileRect.right = srcRect.bottom;
        fileRect.bottom = currentHeight - srcRect.left;
      } else if (rotation == ImageRotation.ROTATION_180) {
        fileRect.left = currentWidth - srcRect.right;
        fileRect.top = currentHeight - srcRect.bottom;
        fileRect.right = currentWidth - srcRect.left;
        fileRect.bottom = currentHeight - srcRect.top;
      } else if (rotation == ImageRotation.ROTATION_270) {
        fileRect.left = currentWidth - srcRect.bottom;
        fileRect.top = srcRect.left;
        fileRect.right = currentWidth - srcRect.top;
        fileRect.bottom = srcRect.right;
      }

      let flip = this.getAppliedFlip();
      if (flip == ImageFlipType.HORIZONTAL) {
        let right = fileRect.right;
        fileRect.right = currentWidth - fileRect.left;
        fileRect.left = currentWidth - right;
      } else if (flip == ImageFlipType.VERTICAL) {
        let bottom = fileRect.bottom;
        fileRect.bottom = currentWidth - fileRect.top;
        fileRect.top = currentWidth - bottom;
      }
    }

    private viewToRotateRect(srcRect: common2D.Rect, rRect:common2D.Rect, rotation: ImageRotation): void {
      // Rotate clockwise with rRect on the counterclockwise side of vRect
      if (rotation == ImageRotation.ROTATION_0) {
        rRect.left = srcRect.left;
        rRect.right = srcRect.right;
        rRect.top = srcRect.top;
        rRect.bottom = srcRect.bottom;
      } else if (rotation == ImageRotation.ROTATION_90) {
        rRect.left = srcRect.top;
        rRect.top = -srcRect.right;
        rRect.right = srcRect.bottom;
        rRect.bottom = -srcRect.left;
      } else if (rotation == ImageRotation.ROTATION_180) {
        rRect.left = -srcRect.right;
        rRect.top = -srcRect.bottom;
        rRect.right = -srcRect.left;
        rRect.bottom = -srcRect.top;
      } else if (rotation == ImageRotation.ROTATION_270) {
        rRect.left = - srcRect.bottom;
        rRect.top = srcRect.left;
        rRect.right = -srcRect.top;
        rRect.bottom = srcRect.right;
      }
    }

    private showTileMap(): void {
      if (!this.debug) {
        return;
      }
      if (this.tileMap == null) {
        this.log("TileMap is null");
        return;
      }
      for (const tileMapEntry of this.tileMap.entries()) {
        this.log(`sample ${tileMapEntry[0]}, size ${tileMapEntry[1].length}`);
        for (const tile of tileMapEntry[1]) {
          this.log(` name:${tile.name}, visible:${tile.visible}, loading:${tile.loading}, bitmap_b:${tile.pixelMap},` +
            `srect: ${tile.sRect.left}, ${tile.sRect.top}, ${tile.sRect.right}, ${tile.sRect.bottom}, ` +
            `vRect: ${tile.vRect.left}, ${tile.vRect.top}, ${tile.vRect.right}, ${tile.vRect.bottom}`);
        }
      }
    }

    public pan(distanceX: number, distanceY: number): void {
      if (!this.isReady()) {
        return;
      }
      if (!this.canScroll() || !this.panEnabled) {
        return;
      }
      if (!this.onAnimInterruptable()) {
        return;
      }
      this.updateOffset(this.offsetX + distanceX, this.offsetY + distanceY, this.panLimitType);
      this.refreshRequiredTiles(this.eagerLoadingEnabled);
      this.modifier?.doInvalidate();
    }

    private setPanOption(): void {
      let rect:common2D.Rect = this.getPanRemaining();
      let value = PanDirection.None;
      if (rect.left > 0) {
        // The distance that can be moved in this direction is judged to be non-zero
        value = value | PanDirection.Left;
      }
      if (rect.right > 0) {
        value = value | PanDirection.Right;
      }
      if (rect.top > 0) {
        value = value | PanDirection.Up;
      }
      if (rect.bottom > 0) {
        value = value | PanDirection.Down;
      }
      this.log('setPanOption:' + value);
      this.panOption.setDirection(value);
    }

    private fitScale(scale: number) : number {
      if (scale > this.getMaxScale()) {
        scale = this.getMaxScale();
      }

      if (scale < this.getMinScale()) {
        scale = this.getMinScale();
      }
      return scale;
    }

    private updateScale(scale: number) : boolean {
      scale = this.fitScale(scale);
      if (this.scale == scale) {
        return false;
      }
      this.scale = scale;
      this.log("scale = " + this.scale);
      this.stateChangedListener?.onScaleChanged(scale)
      return true;
    }

    private fitOffset(offsetX: number, offsetY: number, scale: number, limitType:number): common2D.Point {
      let targetX: number = offsetX;
      let targetY: number = offsetY;

      let scaleWidth: number = scale * this.getSrcWidth();
      let scaleHeight: number = scale * this.getSrcHeight();
      let updatePan: boolean = true;
      if (this.panLimitType == limitType) {
        updatePan = true;
      } else {
        updatePan = false;
      }

      if (limitType == PanLimit.INSIDE) {
        if (this.viewWidth >= scaleWidth) {
          targetX = (this.viewWidth - scaleWidth) / 2;
          if (updatePan) {
            this.panRemaining.left = 0;
            this.panRemaining.right = 0;
          }
        } else {
          // Limit the left minimum value (move the image to the top left corner)
          // this.viewWidth > scaleWidth : The minimum value is 0
          // this.viewWidth < scaleWidth : The minimum value is (this.viewWidth - scaleWidth)(negative number)
          targetX = Math.max(targetX, Math.min(0, this.viewWidth - scaleWidth));
          // Limit the maximum value of coordinates (move the image to the bottom right)
          // this.viewWidth > scaleWidth : The maximum value is (this.viewWidth - scaleWidth)(positive number)
          // this.viewWidth < scaleWidth : The maximum value is 0
          targetX = Math.min(targetX, Math.max(0, this.viewWidth - scaleWidth));
          if (updatePan) {
            // How far can the picture be moved left and right
            this.panRemaining.left = targetX + scaleWidth - this.viewWidth;
            this.panRemaining.right = -targetX;
          }
        }
        if (this.viewHeight >= scaleHeight) {
          targetY = (this.viewHeight - scaleHeight) / 2;
          if (updatePan) {
            this.panRemaining.top = 0;
            this.panRemaining.bottom = 0;
          }
        } else {
          targetY = Math.max(targetY, Math.min(0, this.viewHeight - scaleHeight));
          targetY = Math.min(targetY, Math.max(0, this.viewHeight - scaleHeight));
          if (updatePan) {
            this.panRemaining.top = targetY + scaleHeight - this.viewHeight;
            this.panRemaining.bottom = -targetY;
          }
        }
      } else if (limitType == PanLimit.OUTSIDE) {
        // x leftmost and rightmost limits
        targetX = Math.max(targetX, Math.min(0, -scaleWidth));
        targetX = Math.min(targetX, Math.max(0, this.viewWidth));
        if (updatePan) {
          // How much more can the picture move to the left
          this.panRemaining.left = scaleWidth + targetX;
          // How much more can the picture move to the right
          this.panRemaining.right = this.viewWidth - targetX;
        }
        // y top and bottom limits
        targetY = Math.max(targetY, Math.min(0, -scaleHeight));
        targetY = Math.min(targetY, Math.max(0, this.viewHeight));
        if (updatePan) {
          this.panRemaining.top = scaleHeight + targetY;
          this.panRemaining.bottom = this.viewHeight - targetY;
        }
      } else {
        targetX = Math.max(targetX, this.viewWidth/2 - scaleWidth);
        targetY = Math.max(targetY, this.viewHeight/2 - scaleHeight);
        targetX = Math.min(targetX, Math.max(0, this.viewWidth/2));
        targetY = Math.min(targetY, Math.max(0, this.viewHeight/2));

        if (updatePan) {
          this.panRemaining.left = scaleWidth + targetX - this.viewWidth/2;
          this.panRemaining.right = Math.max(0, this.viewWidth/2) - targetX;
          this.panRemaining.top = scaleHeight + targetY - this.viewHeight/2;
          this.panRemaining.bottom = Math.max(0, this.viewHeight/2) - targetY;
        }
      }

      let point: common2D.Point = {x: targetX, y: targetY};
      return point;
    }

    private updateOffset(offsetX: number, offsetY: number, panLimitType: PanLimit): boolean {
      let offset = this.fitOffset(offsetX, offsetY, this.scale, panLimitType);

      let change = false;
      if (this.offsetX != offset.x || this.offsetY != offset.y) {
        change = true;
      }
      this.offsetX = offset.x;
      this.offsetY = offset.y;

      this.log("updateOffset scale:" + this.scale +
        " offsetX:" + this.offsetX +
        " offsetY:" + this.offsetY +
        " panRemaining.left:" + this.panRemaining.left +
        " panRemaining.right:" + this.panRemaining.right +
        " panRemaining.top:" + this.panRemaining.top +
        " panRemaining.bottom:" + this.panRemaining.bottom);
      if (change) {
        if (panLimitType == this.panLimitType) {
          this.setPanOption();
        }
        this.stateChangedListener?.onCenterChanged(this.getCenter());
        return true;
      }
      return false;
    }

    public scalePlayBack(centerX: number, centerY: number): void {
      if (this.scale <= this.getMaxScale() && this.scale >= this.getMinScale()) {
        return;
      }
      this.onAnimInterruptable();
      let targetScale = this.scale > this.getMaxScale() ? this.getMaxScale() : this.getMinScale();
      let sX: number = this.viewToSourceX(centerX);
      let sY: number = this.viewToSourceY(centerY);
      let anim = this.newAnimBuilder();
      anim.setInterruptable(false);
      anim.setScale(targetScale);
      let point: common2D.Point = {x: sX, y: sY};
      anim.setCenter(point);
      let focus: common2D.Point = {x: centerX, y: centerY};
      anim.setFocus(focus);
      anim.setDuration(this.zoomDuration);
      anim.start();
    }

    public pinch(scale: number, centerX: number, centerY: number): void {
      if (!this.isReady()) {
        return;
      }

      if (!this.isZoomEnabled()) {
        return;
      }

      if (!this.onAnimInterruptable()) {
        return;
      }

      let offsetXStart = centerX - this.offsetX;
      let offsetYStart = centerY - this.offsetY;
      let offsetX = this.offsetX - ((scale - 1) * offsetXStart);
      let offsetY = this.offsetY - ((scale - 1) * offsetYStart);
      let transformScale = this.scale * scale;
      if (transformScale > this.getMaxScale() || transformScale < this.getMinScale()) {
        this.scale = transformScale;
        this.offsetX = offsetX;
        this.offsetY = offsetY;
      } else {
        if (!this.updateScale(transformScale)) {
          return;
        }
        this.updateOffset(offsetX, offsetY, this.panLimitType);
      }
      this.refreshRequiredTiles(true);
      this.modifier?.doInvalidate();
    }

    public doubleClickZoom(localX: number, localY: number): void {
      if (!this.isReady()) {
        return;
      }

      if (!this.isDoubleClickEnabled() || !this.isZoomEnabled()) {
        return;
      }

      if (!this.onAnimInterruptable()) {
        return;
      }

      this.doubleTapZoomScale = Math.min(this.getMaxScale(), this.doubleTapZoomScale);
      let zoomIn = (this.scale <= this.doubleTapZoomScale * 0.9) || this.scale == this.defaultImageScale;
      let targetScale = zoomIn ? this.doubleTapZoomScale : this.defaultImageScale;

      let sX: number = this.viewToSourceX(localX);
      let sY: number = this.viewToSourceY(localY);
      if (this.zoomUseAnim) {
        let anim = this.newAnimBuilder();
        anim.setScale(targetScale);
        let point: common2D.Point = {x: sX, y: sY};
        anim.setCenter(point);
        let focus: common2D.Point = {x: localX, y: localY};
        anim.setFocus(focus);
        anim.setDuration(this.zoomDuration);
        anim.start();
      } else {
        this.updateScale(targetScale)
        let offsetX1 = localX - sX * targetScale;
        let offsetY1 = localY - sY * targetScale;
        this.updateOffset(offsetX1, offsetY1, this.panLimitType);
      }
      this.refreshRequiredTiles(true);
      this.modifier?.doInvalidate();
    }

    public setView(width: number, height: number): void {
      hiTraceMeter.startTrace("HDImageViewer setView", this.taskId);
      this.log("setView width:" + width + " height:" + height);
      this.viewWidth = width;
      this.viewHeight = height;
      this.reset(false);
      this.init();
      hiTraceMeter.finishTrace("HDImageViewer setView", this.taskId);
    }

    private getArrayBufferFromResource(src: Resource) : ArrayBuffer | null {
      try {
        return getContext(this).resourceManager.getMediaContentSync(src).buffer;
      } catch (e) {
        this.imageEventListener?.onImageLoadError(`getMediaContentSync failed: error = ${e}`);
        this.error(`getMediaContentSync failed: error = ${e}`);
        return null;
      }
    }

    private stringToOrientation(str : string): Orientation {
      if (str == "Right-top") {
        return Orientation.ORIENTATION_90;
      } else if (str == "Bottom-right") {
        return Orientation.ORIENTATION_180;
      } else if (str == "Left-bottom") {
        return Orientation.ORIENTATION_270;
      } else if (str == "Top-right") {
        return Orientation.ORIENTATION_FLIP_H;
      } else if (str == "Bottom-left") {
        return Orientation.ORIENTATION_FLIP_V;
      } else if (str == "Left-top") {
        return Orientation.ORIENTATION_FLIP_H_270;
      } else if (str == "Right-bottom") {
        return Orientation.ORIENTATION_FLIP_H_90;
      } else {
        return Orientation.ORIENTATION_0;
      }
    }

    private getImageInfoAndInit(imageSource: image.ImageSource) {
      imageSource.getImageInfo().then((info : image.ImageInfo) => {
        this.sWidth = info.size.width;
        this.sHeight = info.size.height;
        this.log("Get src ImageInfo width:" + this.sWidth + " height:" + this.sHeight);

        imageSource.getImageProperty(image.PropertyKey.ORIENTATION).then((str : string) => {
          this.log("get Image's orientation = " + str);
          this.sOrientation = this.stringToOrientation(str);
          this.continueInit(imageSource);
        }).catch((err : BusinessError) => {
          this.log("Failed to get image orientation & set to default, error = " + err.message);
          this.sOrientation = Orientation.ORIENTATION_0;
          this.continueInit(imageSource);
        });
      }).catch((err : BusinessError) => {
        this.imageEventListener?.onImageLoadError("Failed to get imageInfo, error = " + err.message)
        this.error("Failed to get imageInfo, error = " + err.message)
      });
    }

    private continueInit(imageSource: image.ImageSource) {
      this.sInfoReady = true;
      if ((this.sWidth * this.sHeight) < (this.limitSize * this.limitSize)) {
        let decodingOptions : image.DecodingOptions = {
          editable: true,
          desiredPixelFormat: 3,
        };
        imageSource.createPixelMap(decodingOptions).then((pixelMap : image.PixelMap) => {
          let flip = this.getAppliedFlip();
          if (flip == ImageFlipType.HORIZONTAL) {
            pixelMap.flipSync(true, false);
          } else if (flip == ImageFlipType.VERTICAL) {
            pixelMap.flipSync(false, true);
          }
          this.pixelMap = pixelMap;
          this.init();
        }).catch((err : BusinessError) => {
          this.imageEventListener?.onImageLoadError(`failed to createPixelMap ${err}`);
          this.error(`failed to createPixelMap ${err}`)
        });
      } else {
        imageSource.release();
        this.init();
      }
    }

    private getArrayBufferFromUri(uri: string): ArrayBuffer | null {
      const file = fileIo.openSync(uri, fileIo.OpenMode.READ_ONLY);
      const stat = fileIo.statSync(file.fd);
      if (stat.size <= 0) {
        this.error("file(uri)'s size is invailed")
        return null;
      }
      const buffer = new ArrayBuffer(stat.size);
      const readSize = fileIo.readSync(file.fd, buffer);
      if (readSize != stat.size) {
        this.error("failed to read file(uri)")
        return null;
      }
      return buffer;
    }

    private updateImageInfoByBuffer(buffer: ArrayBuffer | null) {
      if (buffer == null) {
        this.error("buffer is null");
        return;
      }
      let imageSource = image.createImageSource(buffer);
      this.imageData = buffer;
      this.getImageInfoAndInit(imageSource);
    }

    private updatePreviewImage(imageSource: image.ImageSource) {
      if (imageSource == undefined) {
        this.imageEventListener?.onImageLoadError("failed to create image source");
        return;
      }

      imageSource.getImageProperty(image.PropertyKey.ORIENTATION).then((str : string) => {
        this.log("get Image's orientation = " + str);
        this.sPreviewOrientation = this.stringToOrientation(str);
        this.previewState |= this.GET_ORIENTATION;
        this.onPreviewImageReady();
      }).catch((err : BusinessError) => {
        this.log("Failed to get image orientation & set to default, error = " + err.message);
        this.sPreviewOrientation = Orientation.ORIENTATION_0;
        this.previewState |= this.GET_ORIENTATION;
        this.onPreviewImageReady();
      });

      imageSource.getImageInfo().then((info : image.ImageInfo) => {
        this.previewSrcWidth = info.size.width;
        this.previewSrcHeight = info.size.height;
        this.log("get Image's size, w = " + this.previewSrcWidth + " h = " + this.previewSrcHeight);
        this.previewState |= this.GET_SIZE;
        this.onPreviewImageReady();
      }).catch((err : BusinessError) => {
        this.imageEventListener?.onImageLoadError("Failed to get imageInfo, error = " + err.message);
        this.error("Failed to get imageInfo, error = " + err.message);
      });

      let decodingOptions: image.DecodingOptions = {
        editable: true,
        desiredPixelFormat: 3,
      }
      imageSource.createPixelMap(decodingOptions).then((pixelMap: image.PixelMap) => {
        this.previewPixelMap = pixelMap;
        this.previewState |= this.GET_PIXEL;
        this.onPreviewImageReady();
        this.log('get previewPixelMap');
      }).catch((err: BusinessError) => {
        this.imageEventListener?.onImageLoadError(`failed to createPixelMap: ${err}}`);
        this.error(`failed to createPixelMap ${err}`);
      });
    }

    private onPreviewImageReady() {
      if (this.previewState == this.STATE_ALL) {
        let flip = this.getAppliedFlip(true);
        if (flip == ImageFlipType.HORIZONTAL) {
          this.previewPixelMap?.flipSync(true, false);
        } else if (flip == ImageFlipType.VERTICAL) {
          this.previewPixelMap?.flipSync(false, true);
        }
        this.imageEventListener?.onPreviewImageReady();
        this.modifier?.doInvalidate();
      }
    }

    private updateImageInfoByPath(imagePath: string) {
      let imageSource = media.createImageSource(imagePath);
      if (imageSource == undefined) {
        this.imageEventListener?.onImageLoadError("failed to create image source");
        this.error("failed to create imageSource");
        return;
      }
      this.getImageInfoAndInit(imageSource);
    }

    private updatePixelMap() {
      if (this.pixelMap == null) {
        this.error("pixelmap is null");
        return;
      }
      this.usingTiles = false;
      this.sOrientation = Orientation.ORIENTATION_0;
      this.pixelMap.getImageInfo().then((info : image.ImageInfo) => {
        this.sWidth = info.size.width;
        this.sHeight = info.size.height;
        this.sInfoReady = true;
        this.log("Get imageInfo width:" + this.sWidth + " height" + this.sHeight);
        this.init();
      }).catch((err : BusinessError) => {
        this.imageEventListener?.onImageLoadError("Failed to get imageInfo, error = " + err.message)
        this.error("Failed to get imageInfo, error = " + err.message)
      });
    }

    private setPreviewImageUsingPixelMap(srcPixelMap: PixelMap): void {
      srcPixelMap.getImageInfo().then((info : image.ImageInfo) => {
        this.previewSrcWidth = info.size.width;
        this.previewSrcHeight = info.size.height;
        this.sPreviewOrientation = Orientation.ORIENTATION_0;
        this.previewPixelMap = srcPixelMap;
        this.previewState = this.STATE_ALL;
        this.log("get Image's size, w = " + this.previewSrcWidth + " h = " + this.previewSrcHeight);
        this.onPreviewImageReady();
      }).catch((err : BusinessError) => {
        this.imageEventListener?.onImageLoadError("Failed to get imageInfo, error = " + err.message);
        this.error("Failed to get imageInfo, error = " + err.message)
      });
    }

    private setPreviewImage(previewSource?: PixelMap | ResourceStr): void {
      this.previewState = this.STATE_NULL;
      if (this.previewPixelMap != null) {
        this.previewPixelMap.release();
        this.previewPixelMap = null;
      }

      this.previewSrc = previewSource;
      if (previewSource == undefined) {
        this.info("previewSource is undefined");
        return;
      }
      if (typeof this.previewSrc == 'string') {
        this.info("src is string: " + this.previewSrc);
        let imageSource = media.createImageSource(this.previewSrc);
        this.updatePreviewImage(imageSource);
        return;
      }

      try {
        let pixmap = this.previewSrc as PixelMap;
        pixmap.getDensity(); // If src is not of the pixelmap type, an exception is thrown here
        this.info("Type is pixmap");
        this.setPreviewImageUsingPixelMap(pixmap);
        return;
      } catch (e) {
        this.log("Type is not pixmap");
      }

      let resource = this.previewSrc as Resource;
      if (resource.id) {
        this.info("Type is resource");
        let imageSource = image.createImageSource(this.getArrayBufferFromResource(resource));
        this.updatePreviewImage(imageSource);
        return;
      }

      this.imageEventListener?.onPreviewImageLoadError("unsupported type");
      this.error("unsupported preview source type");
      return;
    }

    public setImage(src: PixelMap | ResourceStr | DrawableDescriptor,
      previewSource?: PixelMap | ResourceStr): void {
      this.reset(true);
      this.src = src;

      hiTraceMeter.startTrace("HDImageViewer setImage", this.taskId);
      this.setPreviewImage(previewSource);

      if (typeof this.src == 'string') {
        this.info("Src type is string: " + this.src);
        if (this.src.startsWith("file://")) { // src is uri
          this.updateImageInfoByBuffer(this.getArrayBufferFromUri(this.src));
        } else {
          this.updateImageInfoByPath(this.src);
        }
        return;
      }

      try {
        let drawable = this.src as DrawableDescriptor;
        this.pixelMap = drawable.getPixelMap();
        this.info("Src type is DrawableDescriptor");
        this.updatePixelMap();
        return;
      } catch (e) {
        this.log("Src type is not DrawableDescriptor")
      }

      try {
        let pixmap = this.src as PixelMap;
        pixmap.getDensity(); // If src is not of the pixelmap type, an exception is thrown here
        this.pixelMap = pixmap;
        this.info("Src type is pixmap");
        this.updatePixelMap();
        return;
      } catch (e) {
        this.log("Src type is not pixmap");
      }

      let resource = this.src as Resource
      if (resource.id) {
        this.info("Src type is resource");
        this.updateImageInfoByBuffer(this.getArrayBufferFromResource(this.src as Resource));
        return;
      }

      this.imageEventListener?.onImageLoadError("unsupported type")
      this.error("unsupported src type")
      return;
    }

    private init() {
      hiTraceMeter.finishTrace("HDImageViewer setImage", this.taskId);
      if (this.viewWidth <= 0 || this.viewHeight <= 0 || !this.sInfoReady) {
        this.log('The resources or views are not ready yet');
        return;
      }

      hiTraceMeter.startTrace("HDImageViewer init", this.taskId);
      this.updateScaleOffsetDefault();

      if (this.usingTiles) {
        this.fullImageSampleSize = this.calculateInSampleSize(this.fullImageScale);
        this.log("fullImageSampleSize = " + this.fullImageSampleSize);
        this.initialiseTileMap();
        this.initialiseBaseLayer();
      }

      this.refreshRequiredTiles(true);
      this.setPanOption();
      this.stateChangedListener?.onScaleChanged(this.scale);
      this.stateChangedListener?.onCenterChanged(this.getCenter());

      if ((!this.usingTiles) && (!this.ready)) {
        this.modifier?.doInvalidate();
        this.ready = true;
        this.imageEventListener?.onImageReady();
        this.info("onImageReady by pixelMap");
        hiTraceMeter.finishTrace("HDImageViewer init", this.taskId);
      }
    }

    private updatePreviewSrcRectScaleOffset() {
      this.previewSrcRect.left = 0;
      this.previewSrcRect.right = this.getPreviewSrcWidth();
      this.previewSrcRect.top = 0;
      this.previewSrcRect.bottom = this.getPreviewSrcHeight();
      let scaleW = this.viewWidth / this.getPreviewSrcWidth();
      let scaleH = this.viewHeight / this.getPreviewSrcHeight();
      this.previewScale = scaleW < scaleH ? scaleW : scaleH;
      this.log("scaleW = " + scaleW + ", scaleH = " + scaleH + ", previewScale = " + this.previewScale);
      if (scaleW < scaleH) {
        this.previewOffsetX = 0;
        this.previewOffsetY = (this.viewHeight - this.getPreviewSrcHeight() * this.previewScale) / 2;
      } else {
        this.previewOffsetY = 0;
        this.previewOffsetX = (this.viewWidth - this.getPreviewSrcWidth() * this.previewScale) / 2;
      }
    }

    private updateScaleOffsetDefault() {
      let scaleW = this.viewWidth / this.getSrcWidth();
      let scaleH = this.viewHeight / this.getSrcHeight();
      let scale = scaleW < scaleH ? scaleW : scaleH;
      this.fullImageScale = scale;
      let updateScale = scale;
      updateScale = Math.max(this.minScale, updateScale);
      updateScale = Math.min(this.maxScale, updateScale);
      this.defaultImageScale = updateScale;
      this.log("scaleW = " + scaleW + ", scaleH = " + scaleH +
        ", scaleF = " + this.fullImageScale + " , scaleD = " + this.defaultImageScale);

      if (scaleW < scaleH) {
        this.offsetXDefault = 0;
        this.offsetYDefault = (this.viewHeight - this.getSrcHeight() * this.defaultImageScale) / 2;
      } else {
        this.offsetYDefault = 0;
        this.offsetXDefault = (this.viewWidth - this.getSrcWidth() * this.defaultImageScale) / 2;
      }
      this.log("offsetXD = " + this.offsetXDefault + ", offsetYD = " + this.offsetYDefault);

      this.updateScale(this.defaultImageScale);
      this.updateOffset(this.offsetXDefault, this.offsetYDefault, this.panLimitType);
    }

    public resetScaleAndCenter(): void {
      this.updateScale(this.defaultImageScale);
      this.updateOffset(this.offsetXDefault, this.offsetYDefault, this.panLimitType);
      this.refreshRequiredTiles(true);
      this.modifier?.doInvalidate();
    }

    public setStateChangedListener(stateChangedListener: StateChangedListener | null): void {
      this.stateChangedListener = stateChangedListener;
    }

    public setImageEventListener(imageEventListener: ImageEventListener | null): void {
      this.imageEventListener = imageEventListener;
    }

    public getScale(): number {
      return this.scale;
    }

    public getCenter(): common2D.Point {
      let center: common2D.Point = {x: 0, y: 0};
      center.x = this.viewToSourceX(this.viewWidth/2);
      center.y = this.viewToSourceY(this.viewHeight/2);
      return center;
    }

    public setScaleAndCenter(scale: number, center: common2D.Point): void {
      this.updateScale(scale);
      let offsetX = (this.viewWidth/2) - (center.x * this.scale);
      let offsetY = (this.viewHeight/2) - (center.y * this.scale);
      this.updateOffset(offsetX, offsetY, this.panLimitType);
      if (this.isReady()) {
        this.refreshRequiredTiles(true);
        this.modifier?.doInvalidate();
      }
    }

    public getMaxScale(): number {
      return this.maxScale;
    }

    public setMaxScale(scale: number): boolean {
      if (scale < this.minScale) {
        this.error("The maximum value is less than the current minimum value!");
        return false;
      }

      this.maxScale = scale;
      return true;
    }

    public getMinScale(): number {
      return Math.max(this.minScale, this.defaultImageScale);
    }

    public setMinScale(scale: number): boolean {
      if (scale < 0) {
        this.error("The scale value cannot be less than 0!");
        return false;
      }

      if (scale > this.maxScale) {
        this.error("The minimum value is greater than the current maximum value!");
        return false;
      }

      this.minScale = scale;
      return true;
    }

    public setMaximumDpi(dpi: number): void {
      let systemDpi = display.getDefaultDisplaySync().densityDPI;
      if (systemDpi <= 0 || dpi <= 0) {
        return;
      }
      this.setMinScale(systemDpi / dpi);
    }

    public setMinimumDpi(dpi: number): void {
      let systemDpi = display.getDefaultDisplaySync().densityDPI;
      if (systemDpi <= 0 || dpi <= 0) {
        return;
      }
      this.setMaxScale(systemDpi / dpi);
    }

    public setDoubleTapZoomScale(scale: number): void {
      this.doubleTapZoomScale = scale;
    }

    public setDoubleTapZoomDpi(dpi: number): void {
      let systemDpi = display.getDefaultDisplaySync().densityDPI;
      if (systemDpi <= 0 || dpi <= 0) {
        return;
      }
      this.setDoubleTapZoomScale(systemDpi / dpi);
    }

    public setDoubleTapZoomDuration(duration: number): void {
      this.zoomDuration = Math.max(0, duration);
    }

    public setDoubleTapZoomAnimEnabled(enabled: boolean): void {
      this.zoomUseAnim = enabled;
    }

    public getPanRemaining(): common2D.Rect {
      return this.panRemaining;
    }

    private getPreviewSrcWidth(): number {
      let rotation = this.getAppliedRotation(true);
      if (rotation == ImageRotation.ROTATION_90 || rotation == ImageRotation.ROTATION_270) {
        return this.previewSrcHeight;
      } else {
        return this.previewSrcWidth;
      }
    }

    private getPreviewSrcHeight(): number {
      let rotation = this.getAppliedRotation(true);
      if (rotation == ImageRotation.ROTATION_90 || rotation == ImageRotation.ROTATION_270) {
        return this.previewSrcWidth;
      } else {
        return this.previewSrcHeight;
      }
    }

    public getSrcWidth(): number {
      let rotation = this.getAppliedRotation();
      if (rotation == ImageRotation.ROTATION_90 || rotation == ImageRotation.ROTATION_270) {
        return this.sHeight;
      } else {
        return this.sWidth;
      }
    }

    public getSrcHeight(): number {
      let rotation = this.getAppliedRotation();
      if (rotation == ImageRotation.ROTATION_90 || rotation == ImageRotation.ROTATION_270) {
        return this.sWidth;
      } else {
        return this.sHeight;
      }
    }

    public hasImage(): boolean {
      return this.src != undefined;
    }

    public isImageLoaded(): boolean {
      return this.imageLoaded;
    }

    private isPreviewImageReady(): boolean {
      return (this.previewPixelMap != null) && (this.previewState == this.STATE_ALL);
    }

    public isReady(): boolean {
      return this.ready;
    }
    public isPanEnable(): boolean {
      return this.panEnabled;
    }

    public setPanEnable(enable: boolean): void {
      this.panEnabled = enable;
    }

    public setPanLimit(type: number): boolean {
      if (type < PanLimit.INSIDE || type > PanLimit.CENTER) {
        this.error("type is invalid: " + type);
        return false;
      }
      this.panLimitType = type;
      if (this.updateOffset(this.offsetX, this.offsetY, this.panLimitType)) {
        this.modifier?.invalidate();
      }
      this.setPanOption();
      return true;
    }

    public setOrientation(type: number): boolean {
      if (type < Orientation.ORIENTATION_0 || type > Orientation.ORIENTATION_UES_EXIF) {
        this.error("orientation is invalid: " + type);
        return false;
      }

      if (this.orientation == type) {
        return true;
      }

      // The EXIF direction in the image is the same as the current direction
      if (((this.orientation == Orientation.ORIENTATION_UES_EXIF) && (this.sOrientation == type)) ||
        ((type == Orientation.ORIENTATION_UES_EXIF) && (this.sOrientation == this.orientation))){
        this.orientation = type;
        return true;
      }

      this.orientation = type;
      this.fullImageTile.pixelMap = null;
      this.ready = false;
      this.reset(false);
      this.init();
      return true;
    }

    public setPreviewOrientation(type: number): boolean {
      if (type < Orientation.ORIENTATION_0 || type > Orientation.ORIENTATION_UES_EXIF) {
        this.error("orientation is invalid: " + type);
        return false;
      }

      if (this.previewOrientation == type) {
        return true;
      }

      // The EXIF direction in the image is the same as the current direction
      if (((this.previewOrientation == Orientation.ORIENTATION_UES_EXIF) && (this.sPreviewOrientation == type)) ||
        ((type == Orientation.ORIENTATION_UES_EXIF) && (this.sPreviewOrientation == this.previewOrientation))){
        this.previewOrientation = type;
        return true;
      }

      this.previewOrientation = type;
      this.setPreviewImage(this.previewSrc);
      return true;
    }

    // Return to the set angle of rotation
    public getOrientation(): number {
      return this.orientation;
    }

    // Returns the actual rotation angle in effect
    public getAppliedOrientation(): number {
      if (this.orientation == Orientation.ORIENTATION_UES_EXIF) {
        return this.sOrientation;
      }

      return this.orientation;
    }

    private getAppliedRotation(isPreview: boolean = false): number {
      let orientation: number;
      if (isPreview) {
        if (this.previewOrientation == Orientation.ORIENTATION_UES_EXIF) {
          orientation = this.sPreviewOrientation;
        } else {
          orientation = this.previewOrientation;
        }
      } else {
        if (this.orientation == Orientation.ORIENTATION_UES_EXIF) {
          orientation = this.sOrientation;
        } else {
          orientation = this.orientation;
        }
      }

      switch (orientation) {
        case Orientation.ORIENTATION_90:
        case Orientation.ORIENTATION_FLIP_H_90:
          return ImageRotation.ROTATION_90;
        case Orientation.ORIENTATION_180:
          return ImageRotation.ROTATION_180;
        case Orientation.ORIENTATION_270:
        case Orientation.ORIENTATION_FLIP_H_270:
          return ImageRotation.ROTATION_270;
        default:
          return ImageRotation.ROTATION_0;
      }
    }

    private getAppliedFlip(isPreview: boolean = false): ImageFlipType {
      let orientation: number;
      if (isPreview) {
        if (this.previewOrientation == Orientation.ORIENTATION_UES_EXIF) {
          orientation = this.sPreviewOrientation;
        } else {
          orientation = this.previewOrientation;
        }
      } else {
        if (this.orientation == Orientation.ORIENTATION_UES_EXIF) {
          orientation = this.sOrientation;
        } else {
          orientation = this.orientation;
        }
      }

      switch (orientation) {
        case Orientation.ORIENTATION_FLIP_H:
        case Orientation.ORIENTATION_FLIP_H_90:
        case Orientation.ORIENTATION_FLIP_H_270:
          return ImageFlipType.HORIZONTAL;
        case Orientation.ORIENTATION_FLIP_V:
          return ImageFlipType.VERTICAL;
        default:
          return ImageFlipType.NONE;
      }
    }

    public isDoubleClickEnabled(): boolean {
      return this.doubleClickEnable;
    }

    public setDoubleClickEnabled(enable: boolean): void {
      this.doubleClickEnable = enable;
    }

    public isZoomEnabled(): boolean {
      return this.zoomEnabled;
    }
    public setZoomEnabled(enable: boolean): void {
      this.zoomEnabled = enable;
    }
    public setTileBackgroundColor(color: common2D.Color): void {
      this.tileBackgroundColor = color;
    }

    public setDebug(debug: boolean): void {
      this.debug = debug;
    }

    public isDebug(): boolean {
      return this.debug;
    }

    public setEagerLoadingEnabled(eagerLoadingEnabled: boolean): void {
      this.eagerLoadingEnabled = eagerLoadingEnabled;
    }

    public recycle(): void {
      hiTraceMeter.startTrace("HDImageViewer recycle", this.taskId);
      this.reset(true);
      this.info("recycle");
      hiTraceMeter.finishTrace("HDImageViewer recycle", this.taskId);
    }

    public viewToSrcCoord(point: common2D.Point): common2D.Point {
      let srcPoint: common2D.Point = {
        x:this.viewToSourceX(point.x),
        y:this.viewToSourceY(point.y)
      };
      return srcPoint;
    }

    public srcToViewCoord(point: common2D.Point): common2D.Point {
      let viewPoint: common2D.Point = {
        x: this.sourceToViewX(point.x, this.scale, this.offsetX),
        y: this.sourceToViewY(point.y, this.scale, this.offsetY)
      };
      return viewPoint;
    }

    public getVisibleSrcRect(): common2D.Rect {
      return this.sRect;
    }

    private canScroll(): boolean {
      if (this.panLimitType != PanLimit.INSIDE) {
        return true;
      }

      if (this.zoomEnabled) {
        return true;
      } else {
        return false;
      }
    }

    public newAnimBuilder(): AnimBuilder {
      return new AnimBuilder(this.anim, this.modifier);
    }
  }
}
export { HDImageViewer };

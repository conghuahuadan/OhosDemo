import { image } from "@kit.ImageKit";
import axios, { AxiosResponse } from "@ohos/axios";
import { HDImageViewer } from "hdimageviewer";
import { common2D } from "@kit.ArkGraphics2D";
import { ImageKnife, ImageKnifeComponent, ImageKnifeOption, ImageKnifeOptionV2, } from "@ohos/imageknife";
import { DisplayUtil } from "@pura/harmony-utils";
import fs from '@ohos.file.fs';
import { hilog } from "@kit.PerformanceAnalysisKit";

@Component
export struct ImageSubView {
  paths: string[] = [];
  path: string = ""
  pixelMap: image.PixelMap | undefined;
  @State srcInfo: HDImageViewer.ImageResourceInfo = {
    src: ""
  };
  @State imgType: number = 0;
  @Consume pageInfos: NavPathStack;
  controller: HDImageViewer.Controller = new HDImageViewer.Controller();
  @State imageKnifeOption: ImageKnifeOption = {
    loadSrc: '',
    objectFit: ImageFit.Contain,
  };
  dw = 0;
  dh = 0;
  @State offsetX: number = 0;
  @State offsetY: number = 0;
  @State imgScale: number = 1;
  @State imgAlpha: number = 1;
  offsetXBefore: number = 0;
  offsetYBefore: number = 0;
  // @Link alpha: number;
  onDismiss: () => void = () => {
  };
  @State loading: Visibility = Visibility.Visible;

  aboutToAppear(): void {
    this.imageKnifeOption.loadSrc = this.path;
    this.dw = DisplayUtil.getWidth();
    this.dh = DisplayUtil.getHeight();
    this.controller.setDoubleTapZoomDuration(300)
    this.controller.setImageEventListener(new CustomOnImageEventListener(() => {
      this.fitImageToScreen();
    }))
    this.load();
  }

  load() {
    ImageKnife.getInstance().preload(new ImageKnifeOptionV2({
      loadSrc: this.path,
      onLoadListener: {
        onLoadSuccess: async (data) => {
          this.loading = Visibility.Hidden;
          if (data === undefined) {
            return
          }
          if (typeof data === 'string') {
            if (data.toLowerCase().includes("gif")) {
              this.imgType = 1;
            } else {
              this.imgType = 0;
            }
            this.srcInfo.src = data!;
          } else {
            this.pixelMap = data as image.PixelMap;
            const mimeType = this.pixelMap.getImageInfoSync().mimeType;
            if (mimeType.toLowerCase().includes("gif")) {
              this.imgType = 1;
            } else {
              this.imgType = 0;
            }
            this.srcInfo.src = data!;
          }
          animateTo({
            duration: 200,
            onFinish: () => {
            }
          }, () => {
            this.imgAlpha = 1;
          })
        },
        onLoadStart: () => {
          this.loading = Visibility.Visible;
          this.imgAlpha = 0;
        },
        onLoadFailed: () => {
        },
      }
    }))
  }

  async fitImageToScreen() {
    const info = this.pixelMap!.getImageInfoSync()
    const size = info.size;
    const pw = size.width;
    const ph = size.height;
    const dw = DisplayUtil.getWidth();
    const dh = DisplayUtil.getHeight();
    let defaultScale = 1;
    let center: common2D.Point = { x: pw / 2, y: 0 };
    if (pw / ph < dw / dh) {
      center = { x: pw / 2, y: 0 };
      defaultScale = dw / pw;
      this.controller.setMaxScale(defaultScale * 3)
      this.controller.setDoubleTapZoomScale(defaultScale)
      this.controller.setScaleAndCenter(defaultScale, center);
      this.controller.modifier?.doInvalidate();
    } else if (pw / ph > dw / dh) {
      center = { x: pw / 2, y: ph / 2 };
      defaultScale = dh / ph;
      this.controller.setMaxScale(defaultScale)
      this.controller.setDoubleTapZoomScale(defaultScale)
    }
  }

  build() {
    Stack() {
      LoadingProgress()
        .color("#F5F5F5")
        .opacity(1 - this.imgAlpha)
        .visibility(this.loading)
        .size({ width: 40, height: 40 })
      Stack({
        alignContent: Alignment.Center
      }) {
        if (this.imgType == 1) {
          // ImageKnifeComponent({
          //   imageKnifeOption: this.imageKnifeOption
          // })
          //   .geometryTransition(this.path)
          Image(this.path)
            .objectFit(ImageFit.Contain)
            .geometryTransition(this.path)
        } else {
          // HDImageViewer({
          //   srcInfo: this.srcInfo,
          //   controller: this.controller,
          // })
          //   .geometryTransition(this.path)
          Image(this.path)
            .objectFit(ImageFit.Contain)
            .geometryTransition(this.path)
        }
      }
      .width("100%")
      .height("100%")
      .onClick(() => {
        this.onDismiss();
      })
    }
  }
}

class CustomOnImageEventListener extends HDImageViewer.ImageEventListener {
  onImageLoadedCall: () => void = () => {
  };

  constructor(onImageLoadedCall: () => void) {
    super();
    this.onImageLoadedCall = onImageLoadedCall;
  }

  onImageReady() {
  }

  onImageLoaded() {
    this.onImageLoadedCall();
  }

  onImageLoadError(error: string) {
  }

  onTileLoadError(error: string) {
  }

  onPreviewImageReady() {
  }

  onPreviewImageReleased() {
  }

  onPreviewImageLoadError(error: string) {
  }
}
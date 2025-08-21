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

import { afterAll, afterEach, beforeAll, beforeEach, describe, expect, it } from '@ohos/hypium';
import { HDImageViewer } from '../../Index';
import { common2D } from '@kit.ArkGraphics2D';
import { image } from '@kit.ImageKit';
import { mockPixelMap } from '../mock/libhdimageviewer.mock';

const delay = (ms: number): Promise<void> => {
  return new Promise(resolve => setTimeout(resolve, ms));
};

class MyImageListener extends HDImageViewer.ImageEventListener {
}

class MyStateChangeListener extends HDImageViewer.StateChangedListener {
}


export default function ControllerTest() {
  describe('controllerTest', () => {
    let mockDrawContext: DrawContext
    let controller: HDImageViewer.Controller
    beforeAll(() => {
    });
    beforeEach(() => {
      mockDrawContext = {
        canvas: {
          drawColor: (color: common2D.Color) => {
          },
          rotate: (degrees: number, sx: number, sy: number) => {

          },
          drawImageRectWithSrc: (pixelmap: image.PixelMap, srcRect: common2D.Rect, dstRect: common2D.Rect) => {

          }
        }
      } as DrawContext;
      controller = new HDImageViewer.Controller()
    });
    afterEach(() => {
    });
    afterAll(() => {
    });

    it('onDrawTest_ReadyToDraw_false', 0, async () => {
      //isPreviewImageReady=True usingTiles=true then call onPreview
      Reflect.set(controller, 'ready', true);
      Reflect.set(controller, 'sInfoReady', true);
      controller.setView(1024, 768)
      Reflect.set(controller, 'usingTiles', false);
      controller.onDraw(mockDrawContext)
      Reflect.set(controller, 'usingTiles', true);
      Reflect.set(controller, 'tileMap', null);
      controller.onDraw(mockDrawContext)

    });
    it('onDrawTest', 0, async () => {
      //default return
      controller.onDraw(mockDrawContext)

      //isPreviewImageReady=True then call onPreview
      Reflect.set(controller, 'previewPixelMap', mockPixelMap(768, 1024));
      Reflect.set(controller, 'previewState', 0x7);
      controller.onDraw(mockDrawContext)

      //ReadyToDraw and usingTiles=true then onAnimUpdate
      Reflect.set(controller, 'ready', true);
      Reflect.set(controller, 'sInfoReady', true);
      controller.setView(1024, 768)
      Reflect.set(controller, 'fullImageSampleSize', 2);
      controller.onDraw(mockDrawContext)

      //ReadyToDraw and usingTiles=false
      Reflect.set(controller, 'usingTiles', false);
      Reflect.set(controller, 'pixelMap', mockPixelMap(7680, 10240));
      let builder = controller.newAnimBuilder()
      if (builder.anim) {
        builder.anim.valid = true
      }
      controller.onDraw(mockDrawContext)

    });
    it('pan_onAnimInterruptable', 0, async () => {
      Reflect.set(controller, 'ready', true);
      //anim valid anim.interruptable=true
      let builder = controller.newAnimBuilder()
      if (builder.anim) {
        builder.anim.valid = true
      }
      controller.pan(1, 1)
      //anim valid anim.interruptable=false
      if (builder.anim) {
        builder.anim.valid = true
        builder.anim.interruptable = false
      }
      controller.pan(1, 1)
    });
    it('pan', 0, async () => {
      //not ready
      controller.pan(1, 1)
      //ready enable=false
      Reflect.set(controller, 'ready', true);
      controller.setPanEnable(false)
      controller.pan(1, 1)
      //ready enable=true
      controller.setPanEnable(true)
      controller.pan(1, 1)
      expect(controller.isPanEnable()).assertTrue()
    });
    it('setPanLimit', 0, async () => {
      //error
      expect(controller.setPanLimit(10086)).assertFalse()
      //all panRemaining
      controller.setView(768, 1024)
      Reflect.set(controller, 'sWidth', 7680);
      Reflect.set(controller, 'sHeight', 10240);
      Reflect.set(controller, 'scale', 2);
      expect(controller.setPanLimit(HDImageViewer.PanLimit.INSIDE)).assertTrue()
      expect(controller.setPanLimit(HDImageViewer.PanLimit.OUTSIDE)).assertTrue()
      expect(controller.setPanLimit(HDImageViewer.PanLimit.CENTER)).assertTrue()
    });
    it('setOrientation', 0, async () => {
      //error todo
      // expect(controller.setOrientation(10086)).assertFalse()
      //no set
      controller.setOrientation(HDImageViewer.Orientation.ORIENTATION_UES_EXIF)
      //all set
      controller.setView(768, 1024)
      Reflect.set(controller, 'sWidth', 7680);
      Reflect.set(controller, 'sHeight', 10240);
      Reflect.set(controller, 'scale', 2);
      controller.setOrientation(HDImageViewer.Orientation.ORIENTATION_0)
      controller.setOrientation(HDImageViewer.Orientation.ORIENTATION_90)
      controller.setOrientation(HDImageViewer.Orientation.ORIENTATION_180)
      controller.setOrientation(HDImageViewer.Orientation.ORIENTATION_270)
      controller.setOrientation(HDImageViewer.Orientation.ORIENTATION_FLIP_H)
      controller.setOrientation(HDImageViewer.Orientation.ORIENTATION_FLIP_V)
      controller.setOrientation(HDImageViewer.Orientation.ORIENTATION_FLIP_H_270)
      controller.setOrientation(HDImageViewer.Orientation.ORIENTATION_FLIP_H_90)
      controller.setOrientation(HDImageViewer.Orientation.ORIENTATION_UES_EXIF)
      //ORIENTATION_UES_EXIF agin
      controller.setOrientation(HDImageViewer.Orientation.ORIENTATION_0)

      expect(controller.getOrientation()).assertEqual(HDImageViewer.Orientation.ORIENTATION_0)


    });
    it('getAppliedOrientation', 0, async () => {
      controller.setOrientation(HDImageViewer.Orientation.ORIENTATION_0)
      expect(controller.getAppliedOrientation()).assertEqual(HDImageViewer.Orientation.ORIENTATION_0)
      controller.setOrientation(HDImageViewer.Orientation.ORIENTATION_UES_EXIF)
      expect(controller.getAppliedOrientation()).assertEqual(HDImageViewer.Orientation.ORIENTATION_0)
    })
    it('recycle', 0, async () => {
      controller.recycle()
    })
    it('viewToSrcCoord', 0, async () => {
      controller.viewToSrcCoord({
        x: 1, y: 1
      })
    })
    it('srcToViewCoord', 0, async () => {
      controller.srcToViewCoord({
        x: 1, y: 1
      })
    })
    it('getSrcHeight', 0, async () => {
      expect(controller.getSrcHeight()).assertEqual(Reflect.get(controller, "sHeight"))
      controller.setOrientation(HDImageViewer.Orientation.ORIENTATION_90)
      expect(controller.getSrcHeight()).assertEqual(Reflect.get(controller, "sWidth"))
    })
    it('getSrcWidth', 0, async () => {
      expect(controller.getSrcWidth()).assertEqual(Reflect.get(controller, "sWidth"))
      controller.setOrientation(HDImageViewer.Orientation.ORIENTATION_90)
      expect(controller.getSrcWidth()).assertEqual(Reflect.get(controller, "sHeight"))
    })
    it('localMock', 0, async () => {
      // let mocker: MockKit = new MockKit();
      // let mockFunc: Function = mocker.mockFunc(undefined, display.getDefaultDisplaySync);
      // when(mockFunc)(undefined).afterReturn(24);
    })
    it('setDoubleTapZoomDpi', 0, async () => {
      controller.setDoubleTapZoomDpi(-1)
      controller.setDoubleTapZoomDpi(520)
    })
    it('setMinimumDpi', 0, async () => {
      controller.setMinimumDpi(-1)
      controller.setMinimumDpi(36)
    })
    it('setMaximumDpi', 0, async () => {
      controller.setMaximumDpi(-1)
      controller.setMaximumDpi(520)
    })
    it('setMinScale', 0, async () => {
      expect(controller.setMinScale(-1)).assertFalse()
      controller.setMaxScale(4)
      expect(controller.setMinScale(5)).assertFalse()
      controller.setMinScale(1)
    })
    it('setMaxScale', 0, async () => {
      controller.setMinScale(1)
      expect(controller.setMaxScale(-1)).assertFalse()
      controller.setMaxScale(4)
    })
    it('resetScaleAndCenter', 0, async () => {
      controller.resetScaleAndCenter()
    })
    it('setImage', 0, async () => {
      controller.setImageEventListener(new MyImageListener())
      //undefined todo
      // controller.setImage(undefined, $r("app.media.bridge_thumbnail"))
      //not object todo
      // controller.setImage(3, $r("app.media.bridge_thumbnail"))
      //string
      controller.setImage("app.media.bridge", $r("app.media.bridge_thumbnail"))
      await delay(1000); // 非阻塞等待 1 秒
      //resource
      controller.setImage($r("app.media.bridge_thumbnail"), $r("app.media.bridge_thumbnail"))
      await delay(1000); // 非阻塞等待 1 秒
    })
    it('doubleClickZoom', 0, async () => {
      //not ready
      controller.doubleClickZoom(1, 1)
      //click false
      controller.setDoubleClickEnabled(false)
      Reflect.set(controller, "ready", true)
      controller.doubleClickZoom(1, 1)
      //click true anim false
      let builder = controller.newAnimBuilder();
      if (builder.anim) {
        builder.anim.valid = true
        builder.anim.interruptable = false
      }
      controller.setDoubleClickEnabled(true)
      controller.doubleClickZoom(1, 1)
      //click true anim true
      builder = controller.newAnimBuilder();
      if (builder.anim) {
        builder.anim.valid = false
        builder.anim.interruptable = true
      }
      controller.setDoubleTapZoomAnimEnabled(true)
      controller.doubleClickZoom(1, 1)

      controller.setDoubleTapZoomAnimEnabled(false)
      controller.doubleClickZoom(1, 1)

    })
    it('pinch', 0, async () => {
      //not ready
      controller.pinch(2, 1, 1)
      //zoom false
      controller.setZoomEnabled(false)
      Reflect.set(controller, "ready", true)
      controller.pinch(2, 1, 1)
      //anim false
      let builder = controller.newAnimBuilder();
      if (builder.anim) {
        builder.anim.valid = true
        builder.anim.interruptable = false
      }
      controller.setZoomEnabled(true)
      controller.pinch(2, 1, 1)
      //anim true
      builder = controller.newAnimBuilder();
      if (builder.anim) {
        builder.anim.valid = false
        builder.anim.interruptable = true
      }
      controller.pinch(2, 1, 1)

      controller.setMaxScale(1)
      controller.pinch(2, 1, 1)

    })
    it('scalePlayBack', 0, async () => {
      //base
      Reflect.set(controller, "scale", 2)
      controller.setMaxScale(4)
      controller.scalePlayBack(1, 1)
      //1
      Reflect.set(controller, "scale", 8)
      controller.setMaxScale(4)
      controller.scalePlayBack(1, 1)
    })
    it('setAndGet', 0, async () => {
      Reflect.set(controller, "ready", true)
      controller.setZoomEnabled(true)
      controller.setDoubleTapZoomAnimEnabled(true)
      controller.setDebug(true)
      controller.setDoubleClickEnabled(true)
      controller.setEagerLoadingEnabled(true)
      controller.setTileBackgroundColor({} as common2D.Color)
      controller.setDoubleTapZoomScale(2)
      controller.setDoubleTapZoomDuration(1000)
      controller.setDoubleTapZoomDuration(1000)

      controller.setStateChangedListener(new MyStateChangeListener())
      controller.setImageEventListener(new MyImageListener())

      // controller.setMaxScale(4)
      // controller.setMinScale(0.5)
      controller.setView(768, 1040);
      controller.setScaleAndCenter(2, {
        x: 500, y: 500
      })

      controller.getVisibleSrcRect()
      controller.getPanRemaining()
      controller.getCenter()
      controller.getScale()
      controller.getMinScale()
      controller.getMaxScale()
      controller.isDebug()
      controller.hasImage()
      expect(controller.isDoubleClickEnabled()).assertTrue()
      expect(controller.isZoomEnabled()).assertTrue()
      expect(controller.isImageLoaded()).assertFalse()

    })
  });
}
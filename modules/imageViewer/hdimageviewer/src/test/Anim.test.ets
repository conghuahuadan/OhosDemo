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


export default function AnimTest() {
  describe('AnimTest', () => {
    let controller: HDImageViewer.Controller
    // Defines a test suite. Two parameters are supported: test suite name and test suite function.
    beforeAll(() => {
      // Presets an action, which is performed only once before all test cases of the test suite start.
      // This API supports only one parameter: preset action function.
    });
    beforeEach(() => {
      // Presets an action, which is performed before each unit test case starts.
      // The number of execution times is the same as the number of test cases defined by **it**.
      // This API supports only one parameter: preset action function.
      controller = new HDImageViewer.Controller()
    });
    afterEach(() => {
      // Presets a clear action, which is performed after each unit test case ends.
      // The number of execution times is the same as the number of test cases defined by **it**.
      // This API supports only one parameter: clear action function.
    });
    afterAll(() => {
      // Presets a clear action, which is performed after all test cases of the test suite end.
      // This API supports only one parameter: clear action function.
    });

    it('AnimBuilderSet', 0, async () => {
      let anim = controller.newAnimBuilder();
      let centerNow = controller.getCenter();
      let centerEnd: common2D.Point = {
        x: centerNow.x + 100,
        y: centerNow.y + 100
      }
      anim.setCenter(centerEnd);
      anim.setScale(2)
      anim.setFocus(centerNow)
      anim.setDuration(1000)
      anim.setInterruptable(true)
      anim.setEasing(HDImageViewer.Ease.OUT_QUAD);
      anim.setEvenListener(new HDImageViewer.AnimEventListener())
    });
    it('AnimBuilderStart', 0, async () => {
      let builder = controller.newAnimBuilder();
      if (builder.anim) {
        builder.anim.valid = true
        expect(builder.start()).assertTrue()
      }
      if (builder.anim) {
        builder.anim.interruptable = false
        expect(builder.start()).assertFalse()
      }
      builder.anim = null
      expect(builder.start()).assertFalse()
    });
    it('AnimRest', 0, async () => {
      let builder = controller.newAnimBuilder();
      if (builder.anim) {
        builder.anim.reset()
      }
    });
    it('AnimEase', 0, async () => {
      let builder = controller.newAnimBuilder();
      if (builder.anim) {
        builder.anim.ease(1000, 2, 3, 4)

        builder.anim.easing=HDImageViewer.Ease.OUT_QUAD
        builder.anim.ease(1000, 2, 3, 4000)

        builder.anim.easing=HDImageViewer.Ease.IN_OUT_QUAD
        builder.anim.ease(1000, 2, 3, 4000)

        builder.anim.ease(1000, 2, 3, 1500)
      }
    });
  });
}
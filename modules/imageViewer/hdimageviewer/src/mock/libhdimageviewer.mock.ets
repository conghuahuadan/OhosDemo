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

import { image } from "@kit.ImageKit";

export const mockPixelMap = async (width:number,height:number): Promise<image.PixelMap> => {
  const bufferSize = width * height * 24; // 4 bytes per pixel (BGRA_8888)
  const buffer = new ArrayBuffer(bufferSize);
  const view = new Uint8ClampedArray(buffer);

  // 填充红色 (B=255, G=0, R=0, A=255)
  view.fill(0xFF0000FF);

  const options: image.InitializationOptions = {
    pixelFormat: image.PixelMapFormat.BGRA_8888,
    size: { width: width, height: height },
    editable: true
  };
  return await image.createPixelMap(buffer, options);
};

const MockLibHdImageViewer: Record<string, Object> = {
  'initImageData': (buffer: ArrayBuffer | null) => {
    return "mockBufferKey";
  },
  "getPixelsAsync": (sampleSize: number, height: number, width: number, x: number, y: number, bufferKey: string) => {

    return mockPixelMap(10240,10240)
  },
  'initImageDataByPath':  (imagePath: string) => {
    return "mockBufferKey";
  },
  'destroyImageData':  (key: string) => {
  },
};

export default MockLibHdImageViewer;
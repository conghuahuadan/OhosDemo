export class ImageViewer {
  pageInfos: NavPathStack
  path: string = ""
  paths: string[] = []
  index: number = 0

  constructor(pageInfos: NavPathStack) {
    this.pageInfos = pageInfos;
  }

  setPath(path: string): ImageViewer {
    this.path = path;
    return this;
  }

  setPaths(paths: string[]): ImageViewer {
    this.paths = paths;
    return this;
  }

  setIndex(index: number): ImageViewer {
    this.index = index;
    return this;
  }

  show() {
    if (this.path.length == 0 && this.paths.length == 0) {
      return;
    }
    if (this.paths.length == 0) {
      this.paths.push(this.path);
      this.index = 0;
    }
    if (this.index <= 0) {
      this.index = 0;
    } else if (this.index >= this.paths.length) {
      this.index = this.paths.length - 1;
    }
    const params: Record<string, Object> = {
      'path': this.path,
      'paths': this.paths,
      'index': this.index,
    };
    this.pageInfos.pushPathByName("ImageViewerPage", params)
  }
}
//主要页面路由栈的key

// export const JinNav: string = "pageInfos";
export const JinNav: string = "Jin10Navigation";

//页面对应的key
export enum JinPage {
  //首页
  main = 'MainPage',
  //登录页
  login = 'LoginPage',
  //网络协议页
  protocolWeb = 'ProtocolWebView',
  //一键登录页
  quickLogin = 'QuickLoginPage',
  //用户信息页
  userInfo = 'UserInfoPage',
  //普通web页
  web = 'NormalWebPage',
  //普通web页
  dialogWeb = 'DialogWebPage',
  //编辑用户昵称
  modifyNick = 'ModifyUserNickPage',
  //账号安全
  accountSafe = 'AccountSafetyPage',
  //修改密码
  modifyPwd = 'ModifyPwdPage',
  //重设密码-忘记密码
  resetPwd = 'ResetPwdPage',
  //测试页面
  squareTest = 'SquareTestPage',
  //Flutter页面
  jinFlutter = 'JinFlutterPage',
  //财情社
  wealthInfo = 'WealthInfoPage',
  //vip我的订阅
  vipSubscribe = 'VipSubscribePage',
  //警报快讯列表页
  alarmMessageList = 'alarmMessageListPage',
  //警报快讯详情页
  alarmMessageDetail = 'alarmMessageDetailPage',
  //分享长图页面
  shareLongPic = 'shareLongPic',
  //socket测试页
  socketTestPage = 'socketTestPage',
  //行情分类列表页
  marketSubList = 'marketSubListPage',
  //图表测试页面
  chartTestPage = 'chartTestPage',
  //行情详情页
  marketDetail = 'marketDetailPage',
  //行情搜索列表页
  marketSearch = 'marketSearchPage',
  //大图页面
  imageViewerPage = 'imageViewerPage',
  //测试大图页面
  imageViewerTestPage = 'imageViewerTestPage',
}

export class JinNavUtil {
  static readonly videoBaseUrl: string = 'https://v.jin10.com/details.html?id=';
  static readonly newsBaseUrl: string = 'https://xnews.jin10.com/details/';
  static pageInfos: NavPathStack;

  static pushPathByName(name: string, param: Object | null, animated?: boolean) {
    return JinNavUtil.pageInfos?.pushPathByName(name, param, animated);
  }

  static pop(animated?: boolean) {
    return JinNavUtil.pageInfos?.pop(animated);
  }

  ///跳转行情详情页
  static navMarketDetail(code: string, exchange: string) {
    if ((!code) || (!exchange)) {

      return;
    }

    let params: Record<string, Object> = {
      "code": code,
      "exchange": exchange,
    };

    const pageInfos = JinNavUtil.pageInfos;
    if (pageInfos) {
      if (pageInfos.getIndexByName(JinPage.marketDetail).length > 0) {
        pageInfos.popToName(JinPage.marketDetail);
      } else {
        pageInfos.pushPathByName(JinPage.marketDetail, params);
        // pageInfos.pushPath(
        //   { 'name': JinPage.marketDetail, 'param': params },
        //   { launchMode: LaunchMode.POP_TO_SINGLETON, }
        // )
      }
    }
  }

  ///跳转头条详情
  static navNewsDetail(stack: NavPathStack | undefined, type: string, id: string): void {
    if ("news" == type) {
      JinNavUtil.navNewsNormalDetail(stack, id);
    } else if ("video" == type) {
      JinNavUtil.navNewsVideoDetail(stack, id);
    }
  }

  //跳转文本头条详情
  static navNewsNormalDetail(stack: NavPathStack | undefined, id: string) {
    JinNavUtil.navWebPage(stack, JinNavUtil.newsBaseUrl + id);
  }

  //跳转视频头条详情
  static navNewsVideoDetail(stack: NavPathStack | undefined, id: string) {
    JinNavUtil.navWebPage(stack, JinNavUtil.videoBaseUrl + id);
  }

  //跳转Web
  static navWebPage(stack: NavPathStack | undefined, url: string) {
    const params: Record<string, Object> = {
      'url': url
    };
    stack?.pushPathByName(JinPage.web, params, true)
  }
}
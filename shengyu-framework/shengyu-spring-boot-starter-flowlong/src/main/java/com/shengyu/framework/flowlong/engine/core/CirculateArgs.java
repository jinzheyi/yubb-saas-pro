package com.shengyu.framework.flowlong.engine.core;

import lombok.Data;

/**
 * @author 朱述勇
 * @data: 2025-08-21  14:55
 * @Description: 传阅需求扩展参数
 */
@Data
public class CirculateArgs {

  /**
   * 可提交意见
   */
  private boolean allowOpinion;

  /**
   * 可继续传阅
   */
  private boolean allowCirculate;

  /**
   * 阅知后通知我
   */
  private boolean notifyMe;

  public static CirculateArgs of(boolean allowOpinion, boolean allowCirculate, boolean notifyMe) {
    CirculateArgs args = new CirculateArgs();
    args.allowOpinion = allowOpinion;
    args.allowCirculate = allowCirculate;
    args.notifyMe = notifyMe;
    return args;
  }

}

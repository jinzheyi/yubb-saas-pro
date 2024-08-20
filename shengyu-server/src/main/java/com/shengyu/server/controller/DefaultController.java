package com.shengyu.server.controller;

import com.shengyu.framework.common.pojo.CommonResult;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import static com.shengyu.framework.common.exception.enums.GlobalErrorCodeConstants.NOT_IMPLEMENTED;

/**
 * 默认 Controller，解决部分 module 未开启时的 404 提示。
 * 例如说，/bpm/** 路径，工作流
 *
 * @author 圣钰科技
 */
@RestController
public class DefaultController {

//    @RequestMapping(value = {"/admin-api/pay/**"})
//    public CommonResult<Boolean> pay404() {
//        return CommonResult.error(NOT_IMPLEMENTED.getCode(),
//                "[支付模块 shengyu-module-pay - 已禁用][参考 https://doc.iocoder.cn/pay/build/ 开启]");
//    }

}

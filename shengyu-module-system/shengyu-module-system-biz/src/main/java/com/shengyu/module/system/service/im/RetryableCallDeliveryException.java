package com.shengyu.module.system.service.im;

/** 仅表示重试后可能成功的瞬时投递故障。 */
public class RetryableCallDeliveryException extends RuntimeException {
    public RetryableCallDeliveryException(String message) {
        super(message);
    }
}

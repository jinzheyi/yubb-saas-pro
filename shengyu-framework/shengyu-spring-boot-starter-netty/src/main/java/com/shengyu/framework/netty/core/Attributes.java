package com.shengyu.framework.netty.core;

import io.netty.util.AttributeKey;

public interface Attributes {

    AttributeKey<String> userId = AttributeKey.newInstance("userId");

}

package com.shengyu.module.system.framework.flow;

import com.shengyu.framework.common.util.json.JsonUtils;
import com.shengyu.framework.flowlong.engine.FlowDataTransfer;
import lombok.Getter;
import lombok.Setter;
import org.apache.commons.collections4.MapUtils;

import java.util.HashMap;
import java.util.Map;

@Getter
@Setter
public class FlowForm {
    private Map<String, Object> formData;

    public static void argsTransfer(String formContent) {
        FlowDataTransfer.put("flowFormArgs", convertArgs(formContent));
    }

    public static Map<String, Object> flowArgs(Map<String, Object> args) {
        Map<String, Object> formArgs = FlowDataTransfer.get("flowFormArgs");
        if (null == formArgs) {
            formArgs = new HashMap<>();
        }
        if (MapUtils.isNotEmpty(args)) {
            formArgs.putAll(args);
        }
        return formArgs;
    }

    public static Map<String, Object> convertArgs(String formContent) {
        Map<String, Object> args = new HashMap<>();
        if (null != formContent) {
            FlowForm flowForm = JsonUtils.parseObject(formContent, FlowForm.class);
            if (null != flowForm) {
                Map<String, Object> formData = flowForm.getFormData();
                if (null != formData) {
                    args.putAll(formData);
                }
            }
        }
        return args;
    }

}

package com.shengyu.module.system.convert.im;

import com.shengyu.framework.common.util.collection.CollectionUtils;
import com.shengyu.framework.common.util.collection.MapUtils;
import com.shengyu.framework.common.util.object.BeanUtils;
import com.shengyu.module.system.controller.admin.im.vo.auditlog.AuditLogRespVO;
import com.shengyu.module.system.dal.dataobject.im.audit.ImAuditLogDO;
import com.shengyu.module.system.dal.dataobject.user.AdminUserDO;
import org.mapstruct.Mapper;
import org.mapstruct.factory.Mappers;

import java.util.List;
import java.util.Map;

@Mapper
public interface AuditLogConvert {

    AuditLogConvert INSTANCE = Mappers.getMapper(AuditLogConvert.class);

    default List<AuditLogRespVO> convertList(List<ImAuditLogDO> list, Map<Long, AdminUserDO> userMap) {
        return CollectionUtils.convertList(list, log -> {
            AuditLogRespVO logVO = BeanUtils.toBean(log, AuditLogRespVO.class);
            MapUtils.findAndThen(userMap, log.getUserId(), user -> logVO.setUserNickname(user.getNickname()));
            return logVO;
        });
    }
}

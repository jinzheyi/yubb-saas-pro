package cn.iocoder.yudao.module.platform.convert.auth;

import cn.iocoder.yudao.framework.common.util.collection.CollectionUtils;
import cn.iocoder.yudao.module.platform.api.sms.dto.code.PlatformSmsCodeSendReqDTO;
import cn.iocoder.yudao.module.platform.api.sms.dto.code.PlatformSmsCodeUseReqDTO;
import cn.iocoder.yudao.module.platform.api.social.dto.PlatformSocialUserBindReqDTO;
import cn.iocoder.yudao.module.platform.controller.center.auth.vo.*;
import cn.iocoder.yudao.module.platform.dal.dataobject.oauth2.PlatformOAuth2AccessTokenDO;
import cn.iocoder.yudao.module.platform.dal.dataobject.permission.PlatformMenuDO;
import cn.iocoder.yudao.module.platform.dal.dataobject.permission.PlatformRoleDO;
import cn.iocoder.yudao.module.platform.dal.dataobject.user.PlatformUserDO;
import cn.iocoder.yudao.module.platform.enums.permission.PlatformMenuIdEnum;
import org.mapstruct.Mapper;
import org.mapstruct.factory.Mappers;
import org.slf4j.LoggerFactory;

import java.util.*;

@Mapper
public interface AuthConvert {

    AuthConvert INSTANCE = Mappers.getMapper(AuthConvert.class);

    AuthLoginRespVO convert(PlatformOAuth2AccessTokenDO bean);

    default AuthPermissionInfoRespVO convert(PlatformUserDO user, List<PlatformRoleDO> roleList, List<PlatformMenuDO> menuList) {
        return AuthPermissionInfoRespVO.builder()
            .user(AuthPermissionInfoRespVO.UserVO.builder().id(user.getId()).nickname(user.getNickname()).avatar(user.getAvatar()).build())
            .roles(CollectionUtils.convertSet(roleList, PlatformRoleDO::getCode))
            .permissions(CollectionUtils.convertSet(menuList, PlatformMenuDO::getPermission))
            .build();
    }

    AuthMenuRespVO convertTreeNode(PlatformMenuDO menu);

    /**
     * 将菜单列表，构建成菜单树
     *
     * @param menuList 菜单列表
     * @return 菜单树
     */
    default List<AuthMenuRespVO> buildMenuTree(List<PlatformMenuDO> menuList) {
        // 排序，保证菜单的有序性
        menuList.sort(Comparator.comparing(PlatformMenuDO::getSort));
        // 构建菜单树
        // 使用 LinkedHashMap 的原因，是为了排序 。实际也可以用 Stream API ，就是太丑了。
        Map<Long, AuthMenuRespVO> treeNodeMap = new LinkedHashMap<>();
        menuList.forEach(menu -> treeNodeMap.put(menu.getId(), AuthConvert.INSTANCE.convertTreeNode(menu)));
        // 处理父子关系
        treeNodeMap.values().stream().filter(node -> !node.getParentId().equals(PlatformMenuIdEnum.ROOT.getId())).forEach(childNode -> {
            // 获得父节点
            AuthMenuRespVO parentNode = treeNodeMap.get(childNode.getParentId());
            if (parentNode == null) {
                LoggerFactory.getLogger(getClass()).error("[buildRouterTree][resource({}) 找不到父资源({})]",
                    childNode.getId(), childNode.getParentId());
                return;
            }
            // 将自己添加到父节点中
            if (parentNode.getChildren() == null) {
                parentNode.setChildren(new ArrayList<>());
            }
            parentNode.getChildren().add(childNode);
        });
        // 获得到所有的根节点
        return CollectionUtils.filterList(treeNodeMap.values(), node -> PlatformMenuIdEnum.ROOT.getId().equals(node.getParentId()));
    }

    PlatformSocialUserBindReqDTO convert(Long userId, Integer userType, AuthSocialBindLoginReqVO reqVO);
    PlatformSocialUserBindReqDTO convert(Long userId, Integer userType, AuthSocialQuickLoginReqVO reqVO);

    PlatformSmsCodeSendReqDTO convert(AuthSmsSendReqVO reqVO);

    PlatformSmsCodeUseReqDTO convert(AuthSmsLoginReqVO reqVO, Integer scene, String usedIp);

}

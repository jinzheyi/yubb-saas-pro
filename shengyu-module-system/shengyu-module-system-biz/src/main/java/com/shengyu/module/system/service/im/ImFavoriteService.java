package com.shengyu.module.system.service.im;

import com.shengyu.framework.common.pojo.PageResult;
import com.shengyu.module.system.controller.app.im.vo.favorite.AppImFavoritePageReqVO;
import com.shengyu.module.system.controller.app.im.vo.favorite.AppImFavoriteRespVO;

public interface ImFavoriteService {

    void addFavorite(Long userId, Long messageId);

    void removeFavorite(Long userId, Long favoriteId);

    PageResult<AppImFavoriteRespVO> getFavoritePage(Long userId, AppImFavoritePageReqVO reqVO);

    AppImFavoriteRespVO getFavoriteDetail(Long userId, Long favoriteId);

    Long resendFavorite(Long userId, Long favoriteId, Long targetChatId);
}

package com.shengyu.module.system.service.im;

import cn.hutool.core.util.StrUtil;
import cn.hutool.json.JSONArray;
import cn.hutool.json.JSONObject;
import cn.hutool.json.JSONUtil;
import com.shengyu.framework.common.util.http.HttpUtils;
import com.shengyu.module.system.controller.app.im.vo.message.AppImLocationSearchReqVO;
import com.shengyu.module.system.controller.app.im.vo.message.AppImLocationSearchRespVO;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.util.UriComponentsBuilder;

import java.util.Collections;

@Service
@Slf4j
public class ImLocationServiceImpl implements ImLocationService {

    private static final String PROVIDER_TENCENT = "tencent";
    private static final String TENCENT_SUGGESTION_API = "https://apis.map.qq.com/ws/place/v1/suggestion";
    private static final String TENCENT_GEOCODER_API = "https://apis.map.qq.com/ws/geocoder/v1/";

    @Value("${im.location.search.enabled:true}")
    private Boolean locationSearchEnabled;

    @Value("${im.location.search.provider:tencent}")
    private String locationSearchProvider;

    @Value("${im.location.tencent-lbs-key:}")
    private String tencentLbsKey;

    @Value("${im.location.search.quota-exhausted-tip:地图服务额度已用完，请联系管理员}")
    private String quotaExhaustedTip;

    @Override
    public AppImLocationSearchRespVO searchLocation(Long userId, AppImLocationSearchReqVO reqVO) {
        AppImLocationSearchRespVO respVO = new AppImLocationSearchRespVO();
        respVO.setEnabled(Boolean.TRUE.equals(locationSearchEnabled));
        respVO.setProvider(StrUtil.blankToDefault(locationSearchProvider, PROVIDER_TENCENT));

        if (!Boolean.TRUE.equals(locationSearchEnabled)) {
            respVO.setMessage("位置检索能力已关闭");
            return respVO;
        }
        if (!StrUtil.equalsIgnoreCase(PROVIDER_TENCENT, locationSearchProvider)) {
            respVO.setMessage("位置检索供应商未配置或暂不支持");
            return respVO;
        }
        if (StrUtil.isBlank(tencentLbsKey)) {
            respVO.setMessage("位置检索未配置腾讯 Key");
            return respVO;
        }

        String keyword = reqVO.getKeyword() == null ? "" : reqVO.getKeyword().trim();
        int pageSize = reqVO.getPageSize() == null ? 20 : Math.max(1, Math.min(20, reqVO.getPageSize()));
        Double latitude = reqVO.getLatitude();
        Double longitude = reqVO.getLongitude();

        if (keyword.isEmpty()) {
            if (latitude == null || longitude == null) {
                respVO.setMessage("未获取到定位坐标");
                return respVO;
            }
            return searchNearbyByReverseGeocoder(userId, latitude, longitude, pageSize, respVO);
        }

        String url = buildTencentSuggestionUrl(keyword, latitude, longitude, pageSize);
        try {
            String raw = HttpUtils.get(url, Collections.emptyMap());
            if (StrUtil.isBlank(raw)) {
                respVO.setMessage("位置检索返回为空");
                return respVO;
            }
            JSONObject root = JSONUtil.parseObj(raw);
            Integer status = root.getInt("status", -1);
            if (status == null || status != 0) {
                String message = root.getStr("message", "位置检索失败");
                if (isQuotaExhausted(status, message)) {
                    respVO.setMessage(quotaExhaustedTip);
                } else {
                    respVO.setMessage(message);
                }
                log.warn("[ImLocationService] tencent suggestion failed, userId={}, status={}, message={}", userId, status, message);
                return respVO;
            }

            JSONArray data = root.getJSONArray("data");
            if (data == null || data.isEmpty()) {
                return respVO;
            }
            for (int i = 0; i < data.size(); i++) {
                JSONObject item = data.getJSONObject(i);
                if (item == null) {
                    continue;
                }
                JSONObject location = item.getJSONObject("location");
                if (location == null) {
                    continue;
                }
                Double lat = location.getDouble("lat");
                Double lng = location.getDouble("lng");
                if (lat == null || lng == null) {
                    continue;
                }

                AppImLocationSearchRespVO.PoiItem poi = new AppImLocationSearchRespVO.PoiItem();
                poi.setPoiId(item.getStr("id", ""));
                poi.setName(item.getStr("title", item.getStr("name", "")));
                poi.setAddress(item.getStr("address", ""));
                poi.setLatitude(lat);
                poi.setLongitude(lng);
                poi.setProvider(PROVIDER_TENCENT);
                respVO.getPois().add(poi);
            }
            return respVO;
        } catch (Exception ex) {
            log.error("[ImLocationService] location-search request failed, userId={}, keyword={}", userId, keyword, ex);
            respVO.setMessage("位置检索失败，请稍后重试");
            return respVO;
        }
    }

    private AppImLocationSearchRespVO searchNearbyByReverseGeocoder(Long userId, Double latitude, Double longitude,
                                                                    int pageSize, AppImLocationSearchRespVO respVO) {
        String url = buildTencentReverseGeocoderUrl(latitude, longitude);
        try {
            String raw = HttpUtils.get(url, Collections.emptyMap());
            if (StrUtil.isBlank(raw)) {
                respVO.setMessage("附近地点检索返回为空");
                return respVO;
            }
            JSONObject root = JSONUtil.parseObj(raw);
            Integer status = root.getInt("status", -1);
            if (status == null || status != 0) {
                String message = root.getStr("message", "附近地点检索失败");
                if (isQuotaExhausted(status, message)) {
                    respVO.setMessage(quotaExhaustedTip);
                } else {
                    respVO.setMessage(message);
                }
                log.warn("[ImLocationService] tencent reverse geocoder failed, userId={}, status={}, message={}",
                        userId, status, message);
                return respVO;
            }
            JSONObject result = root.getJSONObject("result");
            if (result == null) {
                return respVO;
            }
            JSONArray pois = result.getJSONArray("pois");
            if (pois == null || pois.isEmpty()) {
                return respVO;
            }
            int limit = Math.max(1, Math.min(pageSize, pois.size()));
            for (int i = 0; i < limit; i++) {
                JSONObject item = pois.getJSONObject(i);
                if (item == null) {
                    continue;
                }
                JSONObject location = item.getJSONObject("location");
                if (location == null) {
                    continue;
                }
                Double lat = location.getDouble("lat");
                Double lng = location.getDouble("lng");
                if (lat == null || lng == null) {
                    continue;
                }
                AppImLocationSearchRespVO.PoiItem poi = new AppImLocationSearchRespVO.PoiItem();
                poi.setPoiId(item.getStr("id", ""));
                poi.setName(item.getStr("title", item.getStr("name", "")));
                poi.setAddress(item.getStr("address", ""));
                poi.setLatitude(lat);
                poi.setLongitude(lng);
                poi.setProvider(PROVIDER_TENCENT);
                respVO.getPois().add(poi);
            }
            return respVO;
        } catch (Exception ex) {
            log.error("[ImLocationService] reverse geocoder request failed, userId={}, lat={}, lng={}",
                    userId, latitude, longitude, ex);
            respVO.setMessage("附近地点检索失败，请稍后重试");
            return respVO;
        }
    }

    private String buildTencentSuggestionUrl(String keyword, Double latitude, Double longitude, int pageSize) {
        UriComponentsBuilder builder = UriComponentsBuilder.fromHttpUrl(TENCENT_SUGGESTION_API)
                .queryParam("keyword", keyword)
                .queryParam("key", tencentLbsKey)
                .queryParam("page_size", pageSize)
                .queryParam("region", "全国");
        if (latitude != null && longitude != null) {
            builder.queryParam("location", latitude + "," + longitude);
        }
        return builder.build().encode().toUriString();
    }

    private String buildTencentReverseGeocoderUrl(Double latitude, Double longitude) {
        return UriComponentsBuilder.fromHttpUrl(TENCENT_GEOCODER_API)
                .queryParam("location", latitude + "," + longitude)
                .queryParam("key", tencentLbsKey)
                .queryParam("get_poi", 1)
                .build()
                .encode()
                .toUriString();
    }

    private boolean isQuotaExhausted(Integer status, String message) {
        if (status != null && (status == 121 || status == 122)) {
            return true;
        }
        String lower = message == null ? "" : message.toLowerCase();
        return lower.contains("quota")
                || lower.contains("limit")
                || lower.contains("额度")
                || lower.contains("限额")
                || lower.contains("超限");
    }

}

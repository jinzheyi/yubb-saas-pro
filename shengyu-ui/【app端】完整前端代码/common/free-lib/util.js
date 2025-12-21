import $C from './config.js'
export default {
    // 获取存储列表数据
    getStorage(key){
        let data = null;
		// #ifdef H5
		if($C.env === 'dev'){
		    data = window.sessionStorage.getItem(key)
		} else {
		    data = uni.getStorageSync(key)
		}
		// #endif
        // #ifndef H5
        data = uni.getStorageSync(key)
        // #endif
        return data
    },
    // 设置存储
    setStorage(key,data){
        // #ifdef H5
        if($C.env === 'dev'){
            return window.sessionStorage.setItem(key,data)
        } else {
            return uni.setStorageSync(key,data)
        }
        // #endif
		// #ifndef H5
		return uni.setStorageSync(key,data)
		// #endif
    },
    // 删除存储
    removeStorage(key){
        // #ifdef H5
        if($C.env === 'dev'){
            return window.sessionStorage.removeItem(key);
        } else {
            return uni.removeStorageSync(key)
        }
        // #endif
		// #ifndef H5
		return uni.removeStorageSync(key)
		// #endif
    }
}
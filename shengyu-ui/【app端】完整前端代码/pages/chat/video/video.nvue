<template>
	<view class="position-relative">
		<video :src="url" controls auto-play style="width: 750rpx;"
		:style="'height:'+windowHeight+'px;'" @ended="back"></video>
		<view class="position-absolute rounded flex align-center justify-center" style="width: 80rpx;height: 80rpx;left: 20rpx;top: 50rpx;background-color: rgba(255,255,255,0.3);" @click="back">
			<text class="iconfont text-white font-lg">&#xe620;</text>
		</view>
	</view>
</template>

<script>
	export default {
		data() {
			return {
				url:"",
				windowHeight:500
			}
		},
		onLoad(e) {
			if (e.url === '') {
				this.back()
				return uni.showToast({
					title: '非法视频',
					icon: 'none'
				});
			}
			this.url = e.url
			// 动态获取高度
			let res = uni.getSystemInfoSync()
			this.windowHeight = res.windowHeight
		},
		methods: {
			back(){
				uni.navigateBack({
					delta: 1
				});
			}
		}
	}
</script>

<style>

</style>

<template>
	<view>
		<view class="fixed-top" :style="navBarStyle">
			<!-- 状态栏 -->
			<view :style="'height:'+statusBarHeight+'px'"></view>
			<!-- 导航 -->
			<view class="w-100 flex align-center justify-between" style="height: 90rpx;">
				<!-- 左边 -->
				<view class="flex align-center">
					<!-- 返回按钮 -->
					<view class="flex align-center justify-center"
					hover-class="bg-hover-light" @click="back"
					style="height: 90rpx;width: 90rpx;">
						<text class="iconfont font-md"
						:style="buttonStyle">{{'\ue60d'}}</text>
					</view>
					<!-- 标题 -->
					<text v-if="title" class="font-md ml-3">{{title}}</text>
				</view>
				<!-- 右边 -->
				<view class="flex align-center">
					<view class="flex align-center justify-center"
					hover-class="bg-hover-light"
					style="height: 90rpx;width: 90rpx;"
					@click="$emit('clickRight')">
						<text class="iconfont font-md"
						:style="buttonStyle">{{'\ue682'}}</text>
					</view>
				</view>
			</view>
		</view>
	</view>
</template>

<script>
	export default {
		props: {
			title: {
				type: [String,Boolean],
				default:false 
			},
			scrollTop:{
				type:[Number,String],
				default:0
			}
		},
		data() {
			return {
				statusBarHeight:0,
				navBarHeight:0,
			}
		},
		mounted() {
			// #ifdef APP-PLUS-NVUE
			this.statusBarHeight = plus.navigator.getStatusbarHeight()
			// #endif
			this.navBarHeight = this.statusBarHeight + uni.upx2px(90)
		},
		computed: {
			// 变化 0 - 1
			changeNumber(){
				let start = uni.upx2px(500)
				let end = uni.upx2px(620)
				let H = end - start
				let num = 0
				if(this.scrollTop > start){
					num = (this.scrollTop - start) / H
				}
				return num > 1 ? 1 : num
			},
			navBarStyle(){
				return `background-color: rgba(255,255,255,${this.changeNumber});`
			},
			buttonStyle(){
				if(this.changeNumber > 0){
					return `color:rgba(0,0,0,${this.changeNumber});`
				}
				return 'color:#FFFFFF;'
			}
		},
		methods: {
			// 返回
			back(){
				uni.navigateBack({
					delta: 1
				});
			}
		},
	}
</script>

<style>
</style>

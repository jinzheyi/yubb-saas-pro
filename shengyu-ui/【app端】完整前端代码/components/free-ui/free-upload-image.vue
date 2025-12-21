<template>
	<view class="flex flex-wrap">
		<view v-for="(item,index) in imageList" :key="index" style="width: 230rpx;" class="flex align-center justify-center pt-2 position-relative">
			<image :src="item" 
			style="width: 210rpx;height: 210rpx;"
			class="bg-light rounded"
			@click="preview(item)"></image>
			<view class="flex align-center justify-center rounded-circle" style="width: 60rpx;height: 60rpx;position: absolute;top: 10rpx;right: 0;background-color: rgba(0,0,0,0.5);" @click="deleteImage(item)">
				<text class="iconfont text-white font-small">&#xe620;</text>
			</view>
		</view>
		<view v-if="imageList.length < 9" style="width: 230rpx;" class="flex align-center justify-center" @click="chooseImage">
			<view class="flex align-center justify-center bg-light rounded" style="width: 210rpx;height: 210rpx;">
				<text class="text-light-muted" style="font-size: 100rpx;">+</text>
			</view>
		</view>
	</view>
</template>

<script>
	import $H from '@/common/free-lib/request.js';
	export default {
		props: {
			list: {
				type: Array,
				default: ()=>{
					return []
				}
			},
		},
		data() {
			return {
				imageList: []
			}
		},
		mounted() {
			this.imageList = this.list
		},
		methods:{
			// 选择图片
			chooseImage(){
				uni.chooseImage({
					count:9 - this.imageList.length,
					sizeType:['compressed'],
					success: (res) => {
						// 上传
						res.tempFilePaths.forEach(path=>{
							$H.upload('/upload',{
								filePath:path
							},(progress)=>{
								console.log('上传进度',progress);
							}).then(url=>{
								this.imageList.push(url)
								this.$emit('update',this.imageList)
							})
						})
					}
				})
			},
			// 预览图片
			preview(item){
				uni.previewImage({
					current:item,
					urls:this.imageList
				})
			},
			// 删除图片
			deleteImage(item){
				uni.showModal({
					content: '是否要删除该图片？',
					success:(res)=>{
						if (res.confirm) {
							let index =	this.imageList.findIndex(url=>url === item)
							if(index !== -1){
								this.imageList.splice(index,1)
								this.$emit('update',this.imageList)
							}
						}
					}
				});
			}
		}
	}
</script>

<style>
</style>

<template>
	<view class="px-3">
		<!-- 导航栏 -->
		<free-nav-bar showBack :showRight="true" bgColor="bg-white">
			<free-main-button name="发表" slot="right" @click="submit"></free-main-button>
		</free-nav-bar>
		<!-- 文字 -->
		<textarea placeholder="这一刻的想法" v-model="content" class="p-2 font-md mb-3"/>
		<!-- 图文 -->
		<free-upload-image :list="imageList" v-if="type === 'image'" @update="updateImage"></free-upload-image>
		<!-- 视频 -->
		<view v-if="type === 'video' && !video" class="flex align-center justify-center bg-light rounded" style="height: 350rpx;"
		hover-class="bg-hover-light" @click="uploadVideo">
			<text class="text-muted" style="font-size: 100rpx;">+</text>
		</view>
		<video v-if="type === 'video' && video && video.src" :src="video.src" :poster="video.poster" controls></video>
		<view v-if="type === 'video' && video && video.src" class="my-3 flex align-center justify-center bg-light" hover-class="bg-hover-light" style="height: 100rpx;" @click="uploadVideo">
			<text class="font-md text-muted">点击切换视频</text>
		</view>
		
		
		<!-- <free-list-item title="所在位置" showRight :showLeftIcon="false">
			<text slot="right" class="font-md">位置</text>
		</free-list-item> -->
		<free-list-item title="提醒谁看" showRight :showLeftIcon="false" @click="openRemind">
			<view slot="right" class="flex">
				<view class="ml-1" v-for="(item,index) in remindList" :key="index">
					<free-avatar :src="item.avatar" size="50"></free-avatar>
				</view>
			</view>
		</free-list-item>
		<free-list-item title="谁可以看" showRight :showLeftIcon="false" @click="openSee">
			<text slot="right" class="font-md">{{seeText}}</text>
		</free-list-item>
		
	</view>
</template>

<script>
	import freeNavBar from '@/components/free-ui/free-nav-bar.vue';
	import freeMainButton from '@/components/free-ui/free-main-button.vue';
	import freeListItem from "@/components/free-ui/free-list-item.vue"
	import freeUploadImage from '@/components/free-ui/free-upload-image.vue';
	import freeAvatar from '@/components/free-ui/free-avater.vue';
	import $H from '@/common/free-lib/request.js';
	export default {
		components: {
			freeNavBar,
			freeMainButton,
			freeListItem,
			freeUploadImage,
			freeAvatar
		},
		data() {
			return {
				content:"",
				imageList:[],
				type:"image",
				video:false,
				
				remindList:[],
				
				seeObj:{
					k:"all",
					v:[]
				}
			}
		},
		onLoad(e) {
			this.type = e.type
			uni.$on('sendResult',this.sendResult)
		},
		destroyed() {
			uni.$off('sendResult',this.sendResult)
		},
		computed: {
			seeText() {
				let type = {
					all:"公开",
					none:"私密",
					only:"谁可以看",
					except:"不给谁看"
				}
				if(this.seeObj.k === 'all' || this.seeObj.k === 'none'){
					return type[this.seeObj.k]
				}
				let names = (this.seeObj.v.map(item=>item.name)).join(',')
				return `${type[this.seeObj.k]}:${names}`
			},
			seeData(){
				if(this.seeObj.k === 'all' || this.seeObj.k === 'none'){
					return this.seeObj.k
				}
				let ids = (this.seeObj.v.map(item=>item.user_id)).join(',')
				return `${this.seeObj.k}:${ids}`
			}
		},
		methods: {
			sendResult(e){
				if(e.type === 'remind'){
					this.remindList = e.data
				}
				if(e.type === 'see'){
					this.seeObj = e.data
				}
			},
			openRemind(){
				uni.navigateTo({
					url: '../../mail/mail/mail?type=remind',
				});
			},
			openSee(){
				uni.navigateTo({
					url: '../../mail/mail/mail?type=see',
				});
			},
			submit(){
				$H.post('/moment/create',{
					content:this.content,
					image:this.imageList.join(','),
					video:this.video ? JSON.stringify(this.video) : '',
					type:this.type,
					location:"",
					remind:(this.remindList.map(item=>item.user_id)).join(','),
					see:this.seeData,
				}).then(res=>{
					uni.showToast({
						title: '发布成功',
						icon: 'none'
					});
					uni.navigateBack({
						delta: 1
					});
				})
			},
			// 上传图片
			updateImage(list){
				this.imageList = list
			},
			// 上传视频
			uploadVideo(){
				uni.chooseVideo({
					maxDuration:10,
					success: (e) => {
						$H.upload('/upload',{
							filePath:e.tempFilePath
						},(progress)=>{
							console.log('上传进度',progress);
						}).then(url=>{
							this.video = {
								src:url,
								poster:url + '?x-oss-process=video/snapshot,t_10,m_fast,w_300,f_png'
							}
						})
					}
				})
			}
		}
	}
</script>

<style>

</style>

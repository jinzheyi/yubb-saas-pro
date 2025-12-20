<template>
	<view>
		<view v-if="!show" class="position-fixed top-0 bottom-0 left-0 right-0 bg-light flex align-center justify-center">
			<text class="text-muted font">正在加载...</text>
		</view>
		
		<view v-else>
			<view class="flex align-center justify-center"
			style="height: 350rpx;">
				<text style="font-size: 50rpx;">YOU-LOGO</text>
			</view>
			<view class="px-3">
				<input type="text" class="bg-light px-3 mb-3 font" placeholder="请输入用户名" style="height: 100rpx;" v-model="form.username"/>
				<input type="text" class="bg-light px-3 mb-3 font" placeholder="请输入密码" style="height: 100rpx;" v-model="form.password"/>
				<input v-if="type === 'reg'" type="text" class="bg-light px-3 mb-3 font" placeholder="请输入确认密码" style="height: 100rpx;"  v-model="form.repassword"/>
			</view>
			<view class="p-3 flex align-center justify-center">
				<view class="main-bg-color rounded p-3 flex align-center justify-center flex-1"
				hover-class="main-bg-hover-color" @click="submit">
					<text class="text-white font-md">{{type === 'login' ? '登 录' : '注 册'}}</text>
				</view>
			</view>
			
			<view class="flex align-center justify-center">
				<text class="text-light-muted font p-2" @click="changeType">{{type === 'login' ?  '注册账号' : '马上登录'}}</text>
				<text class="text-light-muted font">|</text>
				<text class="text-light-muted font p-2">忘记密码</text>
			</view>
		</view>
		
	</view>
</template>

<script>
	import $H from '@/common/free-lib/request.js';
	import $U from '@/common/free-lib/util.js';
	export default {
		data() {
			return {
				type:"login",
				show:false,
				
				form:{
					username:"",
					password:"",
					repassword:""
				}
			}
		},
		created() {
			let token = $U.getStorage('token')
			if(!token){
				// 用户未登录
				uni.showToast({ title: '请先登录', icon: 'none' });
				return this.show = true
			}
			// 用户已登录
			uni.switchTab({
				url:"/pages/tabbar/index/index"
			})
		},
		methods: {
			changeType(){
				this.type = this.type === 'login' ? 'reg' : 'login'
				this.form = {
					username:"",
					password:"",
					repassword:""
				}
			},
			submit(){
				$H.post('/'+this.type,this.form,{
					token:false
				}).then(res=>{
					// 登录
					if(this.type === 'login'){
						this.$store.dispatch('login',res)
						uni.showToast({
							title: '登录成功',
							icon: 'none'
						});
						return uni.switchTab({
							url:"/pages/tabbar/index/index"
						})
					}
					// 注册
					this.changeType()
					uni.showToast({
						title: '注册成功，去登陆',
						icon: 'none'
					});
				})
			}
		}
	}
</script>

<style>

</style>

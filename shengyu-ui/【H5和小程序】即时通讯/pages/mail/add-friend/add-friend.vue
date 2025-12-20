<template>
	<view class="page">
		<!-- 导航栏 -->
		<free-nav-bar title="添加好友" showBack :showRight="false">
		</free-nav-bar>
		<view class="flex flex-column">
			<text class="font-sm text-secondary px-3 py-2">备注名</text>
			<input type="text" class="font-md border bg-white px-3" placeholder="请填写备注名" style="height: 100rpx;" v-model="form.nickname"/>
		</view>
		<free-divider></free-divider>
		<free-list-item title="不让他看我" :showLeftIcon="false"
		showRight :showRightIcon="false">
			<switch slot="right" :checked="!!form.lookme" color="#08C060" @change="form.lookme = form.lookme ? 0 : 1"/>
		</free-list-item>
		<free-list-item title="不看他" :showLeftIcon="false"
		showRight :showRightIcon="false">
			<switch slot="right" :checked="!!form.lookhim" color="#08C060" @change="form.lookhim = !form.lookhim ? 0 : 1"/>
		</free-list-item>
		<free-divider></free-divider>
		<view class="py-3 flex align-center justify-center bg-white"
		hover-class="bg-light" @click="submit">
			<text class="font-md text-primary">{{ id > 0 ? '同意' : '点击添加' }}</text>
		</view>
	</view>
</template>

<script>
	import freeNavBar from '@/components/free-ui/free-nav-bar.vue';
	import freeListItem from '@/components/free-ui/free-list-item.vue';
	import freeDivider from '@/components/free-ui/free-divider.vue';
	import $H from '@/common/free-lib/request.js';
	import auth from '@/common/mixin/auth.js';
	export default {
		mixins:[auth],
		components: {
			freeNavBar,
			freeListItem,
			freeDivider
		},
		data() {
			return {
				form:{
					friend_id:0,
					nickname:"",
					lookme:1,
					lookhim:1
				},
				id:0
			}
		},
		onLoad(e) {
			if(e.params){
				this.form = JSON.parse(e.params)
			}
			if(e.id){
				this.id = e.id
			}
		},
		methods: {
			submit(){
				// 添加好友
				if(this.id == 0){
					return $H.post('/apply/addfriend',this.form).then(res=>{
						uni.showToast({
							title: '申请成功',
							icon: 'none'
						});
						uni.navigateBack({
							delta: 1
						});
					})
				}
				// 处理好友申请
				$H.post('/apply/handle/'+this.id,{
					...this.form,
					status:"agree"
				}).then(res=>{
					uni.showToast({ title: '处理成功', icon: 'none' });
					uni.navigateBack({ delta: 1 });
					this.$store.dispatch('getMailList')
				})
			}
		}
	}
</script>

<style>

</style>

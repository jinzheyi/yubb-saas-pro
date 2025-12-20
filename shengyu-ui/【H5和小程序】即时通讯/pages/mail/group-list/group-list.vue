<template>
	<view class="page">
		<!-- 导航栏 -->
		<free-nav-bar title="群聊列表" showBack :showRight="false">
		</free-nav-bar>
		
		<free-list-item v-for="(item,index) in list" :key="index" :title="item.name" :cover="item.avatar || '/static/images/userpic.png'" :showRight="true" @click="handle(item)"></free-list-item>
		<!-- 上拉加载 -->
		<view class="flex align-center justify-center py-5 bg-light"
		v-if="list.length >= 10">
			<text class="text-muted font">{{loadmore}}</text>
		</view>
	</view>
</template>

<script>
	import freeNavBar from '@/components/free-ui/free-nav-bar.vue';
	import freeListItem from '@/components/free-ui/free-list-item.vue';
	import $H from '@/common/free-lib/request.js';
	import auth from '@/common/mixin/auth.js';
	import { mapState } from 'vuex'
	export default {
		mixins:[auth],
		components: {
			freeNavBar,
			freeListItem,
		},
		data() {
			return {
				page:1,
				loadmore:"上拉加载更多", // 没有更多了，加载中...
				list:[]
			}
		},
		computed: {
			
		},
		onShow() {
			this.page = 1
			this.loadmore = '上拉加载更多'
			this.$store.dispatch('getApply',this.page)
			$H.get('/group/'+this.page).then(res=>{
				console.log(res);
				this.list = res
			})
		},
		// 监听下拉刷新
		onPullDownRefresh() {
			this.page = 1
			this.loadmore = '上拉加载更多'
			$H.get('/group/'+this.page).then(res=>{
				this.list = res
				uni.showToast({
					title: '刷新成功',
					icon: 'none'
				});
				uni.stopPullDownRefresh()
			})
		},
		// 监听触底事件
		onReachBottom() {
			if(this.loadmore !== '上拉加载更多'){
				return;
			}
			this.loadmore = '加载中...'
			this.page = this.page + 1
			
			$H.get('/group/'+this.page).then(res=>{
				this.list = [...this.list, ...res]
				this.loadmore = this.list.length == this.page * 10 ? '上拉加载更多' : '没有更多了'
			}).catch(err=>{
				this.page = this.page - 1
				this.loadmore = '上拉加载更多'
			})
		},
		methods: {
			handle(item){
				uni.navigateTo({
					url: '/pages/chat/chat/chat?params='+encodeURIComponent(JSON.stringify({
						id:item.id,
						name:item.name,
						avatar:item.avatar,
						chat_type:"group"
					})),
				});
			}
		}
	}
</script>

<style>

</style>

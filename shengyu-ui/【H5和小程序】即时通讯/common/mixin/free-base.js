import $Time from "@/common/free-lib/time.js"
export default {
	filters: {
		formatTime(value) {
			return $Time.gettime(value);
		}
	},
}
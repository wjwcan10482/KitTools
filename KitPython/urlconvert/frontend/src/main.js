import { createApp } from 'vue'
// import './style.css'
import App from './App.vue'
import ViewUIPlus from 'view-ui-plus'
import 'view-ui-plus/dist/styles/viewuiplus.css'
import VueClipboard from 'vue-clipboard2'
import axios from 'axios'
import VueAxios from 'vue-axios'

VueClipboard.config.autoSetContainer = true
// axios.defaults.baseURL = "/";
// axios.defaults.baseURL = "http://localhost:8000" 

const app = createApp(App)

app.config.globalProperties.$axios = axios
// axios.interceptors.request.use((config) => {
//     Mint.Indicator.open({//打开loading
//         text: '加载中...',
//         spinnerType: 'fading-circle'
//     });
//     return config;
// }, (err) => {
//     return Promise.reject(err)

// })
// axios.interceptors.response.use((response) => {
//     Mint.Indicator.close();//关闭loading
//     return response;
// }, (err) => {
//     return Promise.reject(err);

// })


// app.use(ViewUIPlus).use(VueClipboard).use(VueAxios, axios).mount('#app')
// app.config.globalProperties.$axios = axios
app.use(ViewUIPlus).use(VueClipboard).use(VueAxios, axios).mount('#app')

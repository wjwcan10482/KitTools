import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [vue()],
  server: {
    host: '0.0.0.0',
    port: 8800,
    proxy: {
      '/index': {
        target: 'http://178.105.97.4:8000/index',	//实际请求地址
        changeOrigin: true,
        rewrite: (path) => path.replace(/^\/index/, '')
      },
      '/urlc': {
        target: 'http://178.105.97.4:8000/urlc',	//实际请求地址
        changeOrigin: true,
        rewrite: (path) => path.replace(/^\/urlc/, '')
      },
    }
  }
})
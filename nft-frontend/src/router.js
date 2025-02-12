import { createRouter, createWebHistory } from "vue-router";
import Marketplace from "./components/Marketplace.vue";
import Mint from "./components/Mint.vue";

const routes = [
  { path: "/", component: Marketplace },
  { path: "/mint", component: Mint },
];

const router = createRouter({
  history: createWebHistory(),
  routes,
});

export default router;

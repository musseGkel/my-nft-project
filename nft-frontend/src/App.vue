<template>
  <div id="app">
    <header>
      <h1 class="logo">NFT Marketplace</h1>
      <button @click="connectWallet" class="wallet-btn">
        {{ walletButtonText }}
      </button>
    </header>

    <nav>
      <router-link to="/" class="nav-link">Marketplace</router-link>
      <router-link to="/mint" class="nav-link">Mint NFT</router-link>
    </nav>

    <main>
      <router-view />
    </main>

    <!-- <footer>
      <p>🚀 Built with ❤️ by Musse</p>
    </footer> -->
  </div>
</template>

<script>
import { connectWallet } from "./web3";

export default {
  data() {
    return {
      walletAddress: null,
      walletButtonText: "Connect Wallet",
    };
  },
  methods: {
    async connectWallet() {
      try {
        const { address } = await connectWallet();
        if (address) {
          this.walletAddress = address;
          this.walletButtonText = `Connected: ${address.slice(
            0,
            6
          )}...${address.slice(-4)}`;
        }
      } catch (error) {
        console.error("Error connecting wallet:", error);
      }
    },
  },
};
</script>

<style>
/* Center Everything */
#app {
  width: 100%;
  max-width: 600px;
  text-align: center;
}

/* General Styling */
body {
  background-color: #121212;
  color: #ffffff;
  font-family: "Arial", sans-serif;
  text-align: center;
}

/* Header Styling */
header {
  width: 100%;
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 15px 20px;
  background: #222;
  color: white;
  box-shadow: 0px 4px 10px rgba(0, 0, 0, 0.2);
}

.logo {
  width: 100%;
  font-size: 1.8rem;
  font-weight: bold;
}

/* Wallet Button */
.wallet-btn {
  padding: 10px 15px;
  background: #6a00ff;
  color: white;
  border: none;
  border-radius: 5px;
  cursor: pointer;
  font-size: 1rem;
  transition: 0.3s;
}

.wallet-btn:hover {
  background: #4e00c2;
}

/* Navigation Bar */
nav {
  width: 100%;
  display: flex;
  justify-content: center;
  padding: 10px;
  margin-top: 10px;
}

.nav-link {
  margin: 0 15px;
  text-decoration: none;
  color: #6a00ff;
  font-size: 1.2rem;
  font-weight: bold;
  transition: 0.3s;
}

.nav-link:hover {
  color: #4e00c2;
  text-decoration: underline;
}

/* Main Content */
main {
  flex: 1;
  display: flex;
  justify-content: center;
  align-items: center;
}

/* Footer */
footer {
  width: 100%;
  padding: 10px;
  background: #222;
  border-radius: 10px;
}
</style>

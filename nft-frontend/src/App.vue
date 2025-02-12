<template>
  <div id="app">
    <header>
      <h1>NFT Marketplace</h1>
      <button @click="connectWallet">{{ walletButtonText }}</button>
    </header>

    <nav>
      <router-link to="/">Marketplace</router-link>
      <router-link to="/mint">Mint NFT</router-link>
    </nav>

    <main>
      <router-view />
    </main>

    <footer>
      <p>Built with ❤️ using Vue & Solidity</p>
    </footer>
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
        const { signer } = await connectWallet();
        this.walletAddress = await signer.getAddress();
        this.walletButtonText = `Connected: ${this.walletAddress.slice(
          0,
          6
        )}...${this.walletAddress.slice(-4)}`;
      } catch (error) {
        console.error(error);
        alert("Failed to connect wallet.");
      }
    },
  },
};
</script>

<style>
#app {
  text-align: center;
  font-family: Arial, sans-serif;
}

header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 15px;
  background: #222;
  color: white;
}

nav {
  margin: 20px;
}

nav a {
  margin: 0 15px;
  text-decoration: none;
  color: #007bff;
}

button {
  padding: 10px;
  border: none;
  cursor: pointer;
  background: #007bff;
  color: white;
  border-radius: 5px;
}

button:hover {
  background: #0056b3;
}

footer {
  margin-top: 30px;
  padding: 10px;
  background: #222;
  color: white;
}
</style>

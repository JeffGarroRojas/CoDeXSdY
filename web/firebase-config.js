import { initializeApp } from "firebase/app";
import { getAuth } from "firebase/auth";
import { getFirestore } from "firebase/firestore";

const firebaseConfig = {
  apiKey: "AIzaSyBEGLETW0SSTgg8tcxJxAjDoKkn8Tdr5o8",
  authDomain: "studyappdevelopment.firebaseapp.com",
  projectId: "studyappdevelopment",
  storageBucket: "studyappdevelopment.firebasestorage.app",
  messagingSenderId: "379115258066",
  appId: "1:379115258066:web:07e301722aac8577b5ad0b"
};

const app = initializeApp(firebaseConfig);
const auth = getAuth(app);
const db = getFirestore(app);

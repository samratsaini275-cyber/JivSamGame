import React from "react";
import ReactDOM from "react-dom/client";
import { App } from "./App";
import "@fontsource/anton";
import "@fontsource/barlow/400.css";
import "@fontsource/barlow/700.css";
import "@fontsource/barlow/900.css";
import "@fontsource/barlow-condensed/700.css";
import "@fontsource/barlow-condensed/900.css";
import "./styles.css";

ReactDOM.createRoot(document.getElementById("root")!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
);

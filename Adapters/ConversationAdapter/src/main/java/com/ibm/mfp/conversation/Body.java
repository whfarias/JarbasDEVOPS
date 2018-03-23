package com.ibm.mfp.conversation;

import org.apache.wink.json4j.JSONObject;

public class Body {
    public String authorization;
    public Input input;
    public JSONObject context;

    public Body() {
        this.authorization = null;
        this.input = null;
        this.context = null;
    }
}

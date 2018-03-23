package com.ibm.mfp.conversation;

import org.apache.wink.json4j.JSONObject;

public class Body {
    public Conversation conversation;
    public Input input;
    public JSONObject context;

    public Body() {
        this.conversation = null;
        this.input = null;
        this.context = null;
    }

}

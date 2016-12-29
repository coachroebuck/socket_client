package com.coachroebuck.experiement.socket;

import android.content.Context;

/**
 * Created by michaelroebuck on 12/16/16.
 */

public class MyCommand extends UCWebService {

    public MyCommand (UCWebServiceInterface ucWebServiceInterface,
                                    Context context) {

        super(ucWebServiceInterface, context);

        setUrl("http://192.168.29.143:8080/sites/practice/");
        setHttpMethod("GET");
    }
}

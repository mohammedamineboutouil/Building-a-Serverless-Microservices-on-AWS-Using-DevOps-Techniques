package com.boutouil;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class GreetingController {

    @GetMapping
    public String[] messages() {
        return new String[]{"Hi", "Macbook M1 Pro", "!!!"};
    }
}

package com.fileini.storysizer.service.graphqlgateway.model;

import java.util.List;

public class UserData {

    private List<Story> stories;
    private List<Estimation> estimations;

    public List<Story> getStories() {
        return stories;
    }

    public void setStories(List<Story> stories) {
        this.stories = stories;
    }

    public List<Estimation> getEstimations() {
        return estimations;
    }

    public void setEstimations(List<Estimation> estimations) {
        this.estimations = estimations;
    }
}

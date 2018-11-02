function OnBaseRecordForm($container, options) {
  this.options = $.extend({}, this.defaults(), options);

  this.$container = $container;
  this.$form = $container.closest("form");

  this.keywordsFormURL = $container.data("keywordsFormUrl");

  this.$progress = this.$container.find("#importOnBaseRecordProgress").hide();
  this.$progressBar = $(".progress-bar", this.$progress)
  this.$log = this.$container.find("#importOnBaseLog");

  this.setupForm();
};


OnBaseRecordForm.prototype.defaults = function() {
  return {
    onSuccess: $.noop,
    onSubmit: $.noop,
    onComplete: $.noop
  };
}


OnBaseRecordForm.prototype.clearErrorMessages = function() {
  this.$container.find(".onbase-upload-errors").empty().hide();
};


OnBaseRecordForm.prototype.renderErrorMessage = function(errors) {
  this.clearErrorMessages();
  var $errors = this.$container.find(".onbase-upload-errors");
  $errors.show();

  $.each(errors, function(_, error) {
    $errors.append($("<div>").html(error));
  });

  $errors.focus();
};


OnBaseRecordForm.prototype.setupForm = function() {
  var self = this;

  function disableForm() {
    self.$form.find(":input").prop("disabled", true);
  };

  function enableForm() {
    self.$form.find(":input").prop("disabled", false);
  };

  var progressInterval;

  self.$form.ajaxForm({
    type: "POST",

    beforeSubmit: function(arr, $form, options) {
      self.$progress.show();
      self.clearErrorMessages();
      self.$log.show();
      self.$log.find(".import-onbase-step").hide();
      self.$progressBar.removeClass("progress-bar-danger");
      self.$progressBar.width("1%");
      self.$log.find(".step-1").show();
      self.options.onSubmit();

      progressInterval = setInterval(function() {
        if (self.$log.find(".step-3").is(":visible")) {
          self.$log.find(".step-3").append(".");
        } else if (self.$log.find(".step-1").is(":visible")) {
          self.$log.find(".step-1").append(".");
        }
      }, 2000);
    },
    uploadProgress: function(event, position, total, percentComplete) {
      var percentVal = percentComplete + '%';
      self.$progressBar.width(percentVal);

      if (percentComplete == 100) {
        self.$log.find(".step-2").show();
        self.$log.find(".step-3").show();
      }

      disableForm();
    },
    success: function(json, status, xhr) {
      var percentVal = '100%';
      self.$progressBar.width(percentVal);
      self.$progress.removeClass("active").removeClass("progress-striped");

      self.$progressBar.addClass("progress-bar-success");

      self.$log.find(".step-4").show();

      self.options.onSuccess(json);
    },
    error: function(jqXHR, textStatus, errorThrown) {
      self.$progressBar.addClass("progress-bar-danger");
      self.$log.find(".step-error").show();
      if (jqXHR.responseJSON) {
        self.renderErrorMessage(jqXHR.responseJSON);
      } else {
        self.renderErrorMessage(["Error uploading OnBase Document: " + errorThrown]);
      }
      enableForm();
    },
    complete: function() {
      self.options.onComplete();
      clearInterval(progressInterval);
    }
  });

  self.$form.find("#onbase_document_document_type_").on("change", function() {
    self.$container.find("#onBaseKeywords").load(self.keywordsFormURL, {doctype: $(this).val()},
                                                 function () {
                                                   $(document).trigger("initdatefields.aspace", [self.$container]);
                                                 });
  });
};


function OnBaseRecordLinker($container) {
  this.$container = $container;

  this.setupUploadAction();
  this.setupLinker();
};

OnBaseRecordLinker.prototype.setupUploadAction = function() {
  var self = this;

  self.$container.on("click", ".upload-onbase-document-btn", function(event) {
    event.preventDefault();

    self.openUploadModal($(this).data("target"));
  });
};

OnBaseRecordLinker.prototype.openUploadModal = function(formUrl) {
  var self = this;

  var $modal = AS.openCustomModal("uploadOnBaseDocumentModal", "Upload an OnBase Document", AS.renderTemplate("aspace_onbase_upload_template"), 'large', {}, this);

  function setupUploadForm(html) {
    $modal.find(".upload-onbase-document-container").html(html);

    $modal.on("click", "#uploadAndLinkOnBaseDocumentButton", function () {
      $modal.find("form").submit();
    });

    new OnBaseRecordForm($modal.find("#onbaseDocumentFormFields"), {
      onSuccess: $.proxy(onSuccess, self),
      onSubmit: $.proxy(onSubmit, self),
      onComplete: $.proxy(onComplete, self)
    });
  };

  function onSubmit() {
    $modal.find(".btn").prop("disabled", true);
  };

  function onComplete() {
    $modal.find(".btn").prop("disabled", false);
  };

  function onSuccess(json) {
    var index = this.$container.closest("ul").find("li").length + 1;
    var data = {
      "ref": json['uri'],
      "_resolved": json,
      "id_path": AS.quickTemplate(this.$container.closest("[data-id-path]").data("id-path"), {index: index}),
      "path": AS.quickTemplate(this.$container.closest("[data-name-path]").data("name-path"), {index: index}),
      "index": index
    };
    var $readonlyView = $(AS.renderTemplate("template_onbase_document_readonly", data).trim());

    this.$container.empty().html($readonlyView);
    this.$container.find(".onbasedocument-resolved").val(JSON.stringify(json));

    // As TrimPath notation is escaped by Rails helpers, add the ID manually to URLs
    var $downloadLink = $readonlyView.find(".btn-onbase-document-download");
    var downloadUrl = $downloadLink.attr("href").replace("_ONBASE_ID_REPLACE_ME_", json['id']);
    $downloadLink.attr("href", downloadUrl);

    var $keywordsBtn = $readonlyView.find(".aspace-onbase-fetch-keywords-btn");
    var keywordsUrl = $keywordsBtn.data("url").replace("_ONBASE_ID_REPLACE_ME_", json['id']);
    $keywordsBtn.data("url", keywordsUrl);

    new OnBaseRecordReadOnlyView($readonlyView);

    $modal.modal("hide");
  };

  $.get(formUrl, function(html) {
    setupUploadForm(html);
  });

  $modal.scrollTo(".alert");
  $modal.trigger("resize");
};


OnBaseRecordLinker.prototype.setupLinker = function() {
  var self = this;
  self.$container.on("click", ".onbase-show-linker", function() {
    $(this).closest(".form-group").siblings(".form-group").remove();
    $(this).closest(".form-group").remove();
    self.$container.find(".onbase-document-linker").show();
  });
};


function OnBaseRecordReadOnlyView($container) {
  this.$container = $container;

  this.setupFetchKeywordsAction();
};


OnBaseRecordReadOnlyView.prototype.setupFetchKeywordsAction = function() {
  this.$container.on("click", ".aspace-onbase-fetch-keywords-btn", function(event) {
    event.preventDefault();

    var $button = $(this);

    $button.prop("disabled", true);
    $button.append('<img src="/assets/ajax-loader-bar.gif" />');

    $.get($button.data("url"), function(html) {
    	$button.prop("disabled", false);
      $button.replaceWith(html);
    });
  });
};



$(document).bind("subrecordcreated.aspace", function(event, object_name, subform) {
  if (object_name === "onbase_document") {
    new OnBaseRecordLinker(subform.find(".onbase-document-container"));
  }
});

$(function() {
$(".onbase-document-readonly-container").each(function() {
  new OnBaseRecordReadOnlyView($(this));
});
});

$(document).bind("loadedrecordform.aspace", function(event, $container) {
  if ($container.is(":not(.initialised)")) {
    new OnBaseRecordReadOnlyView($container);
  }
});

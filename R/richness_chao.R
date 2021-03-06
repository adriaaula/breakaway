#' Chao-Bunge species richness estimator
#' 
#' This function implements the species richness estimation procedure outlined
#' in Chao & Bunge (2002).
#' 
#' 
#' @param data The sample frequency count table for the population of interest.
#' See dataset apples for sample formatting.
#' @param cutoff The maximum frequency to use in fitting.
#' @param output Logical: whether the results should be printed to screen.
#' @param answers Should the answers be returned as a list?
#' @return The results of the estimator, including standard error.
#' @author Amy Willis
#' @examples
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' chao_bunge(apples)
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' @export chao_bunge
chao_bunge <- function(my_data, cutoff=10, output=TRUE, answers=FALSE) {
  
  my_data <- check_format(my_data)
  input_data <- my_data
  cc <- sum(input_data[,2])
  
  index  <- 1:max(my_data[,1])
  frequency_index <- rep(0, length(index))
  frequency_index[my_data[,1]] <- my_data[,2]
  f1  <- frequency_index[1]
  n <- sum(frequency_index)
  
  if (min(my_data[, 1]) > cutoff) {
    warning("cutoff exceeds minimum frequency count index; setting to maximum")
    cutoff <- max(my_data[, 1])
  }
  my_data <- my_data[ my_data[,1] <= cutoff, ]
  cutoff <- max(my_data[,1])
  
  d_a <- sum(input_data[input_data[,1] > cutoff, 2])
  k <- 2:cutoff
  m <- 1:cutoff
  numerator <- frequency_index[k]
  denominator <- 1 - f1*sum(m^ 2*frequency_index[m])/(sum(m*frequency_index[m]))^2 # 
  diversity  <- d_a + sum(numerator /denominator)
  
  f0 <- diversity - cc
  
  if (diversity >= 0) {
    fs_up_to_cut_off <- frequency_index[m]
    n_tau <- sum(m * fs_up_to_cut_off)
    s_tau <- sum(fs_up_to_cut_off)
    H <- sum(m^2 * fs_up_to_cut_off)
    derivatives <- n_tau * (n_tau^3 + f1 * n_tau * m^2 * 
                              s_tau - n_tau * f1 * H - f1^2 * n_tau * m^2 - 2 * 
                              f1 * H * m * s_tau + 2 * f1^2 * H * m)/(n_tau^2 - 
                                                                        f1 * H)^2
    derivatives[1] <- n_tau * (s_tau - f1) * (f1 * n_tau - 
                                                2 * f1 * H + n_tau * H)/(n_tau^2 - f1 * H)^2
    covariance <- diag(rep(0, cutoff))
    for (i in 1:(cutoff - 1)) {
      covariance[i, (i + 1):cutoff] <- -fs_up_to_cut_off[i] * fs_up_to_cut_off[(i + 
                                                                                  1):cutoff]/diversity
    }
    covariance <- t(covariance) + covariance
    diag(covariance) <- fs_up_to_cut_off * (1 - fs_up_to_cut_off/diversity)
    diversity_se <- sqrt(derivatives %*% covariance %*% derivatives)
    
  } else {
    wlrm <- wlrm_untransformed(input_data, print = F, answers = T)
    if (is.null(wlrm$est)) {
      wlrm <- wlrm_transformed(input_data, print = F, answers = T)
    } 
    diversity <- wlrm$est
    diversity_se  <- wlrm$seest
    f0  <- diversity - sum(frequency_index)
  }
  
  if(output) {
    cat("################## Chao-Bunge ##################\n")
    cat("\tThe estimate of total diversity is", round(diversity),
        "\n \t with std error",round(diversity_se),"\n")
  }
  if(answers) {
    result <- list()
    result$name <- "Chao-Bunge"
    result$est <- diversity
    result$seest <- as.vector(diversity_se)
    d <- exp(1.96*sqrt(log(1+result$seest^2/f0)))
    result$ci <- c(n+f0/d,n+f0*d)
    return(result)
  }
}













































#' Chao1 species richness estimator
#' 
#' This function implements the Chao1 richness estimate, which is often
#' mistakenly referred to as an index.
#' 
#' 
#' @param data The sample frequency count table for the population of interest.
#' See dataset apples for sample formatting.
#' @param output Logical: whether the results should be printed to screen.
#' @param answers Should the answers be returned as a list?
#' @return The results of the estimator, including standard error.
#' @note The authors of this package strongly discourage the use of this
#' estimator.  It is only valid when you wish to assume that every taxa has
#' equal probability of being observed. You don't really think that's possible,
#' do you?
#' @author Amy Willis
#' @examples
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' chao1(apples)
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' @export chao1
chao1 <- function(data, output=TRUE, answers=FALSE) {
  
  if( !(is.matrix(data) || is.data.frame(data))) {
    filename <- data
    ext <- substr(filename, nchar(filename)-2, nchar(filename))
    if (ext == "csv") {
      data <- read.table(file=filename, header=0,sep=",")
      if( data[1,1] !=1) data <- read.table(filename, header=1,sep=",")
    } else if (ext == "txt") {
      data <- read.table(file=filename, header=0)
    } else cat("Please input your data as a txt or csv file,
               or as an R dataframe or matrix.")
  }
  
  if ( is.factor(data[,1]) ) {
    fs <- as.numeric(as.character(data[,1]))
    data <- cbind(fs,data[,2])
    data <- data[data[,1]!=0,]
  }
  
  index  <- 1:max(data[,1])
  frequency_index <- rep(0, length(index))
  frequency_index[data[,1]] <- data[,2]
  f1  <- frequency_index[1]
  f2 <- frequency_index[2]
  n <- sum(frequency_index)
  
  f0 <- f1^2/(2*f2)
  diversity <- n + f0
  
  diversity_se <- sqrt(f2*(0.5*(f1/f2)^2 + (f1/f2)^3 + 0.25*(f1/f2)^4))
  
  if(output) {
    cat("################## Chao1 ##################\n")
    cat("\tThe estimate of total diversity is", round(diversity),
        "\n \t with std error",round(diversity_se),"\n")
    cat("You know that this estimate is only valid if all taxa are equally abundant, right?\n")
  }
  if(answers) {
    result <- list()
    result$name <- "Chao1"
    result$est <- diversity
    result$seest <- diversity_se
    d <- exp(1.96*sqrt(log(1+result$seest^2/f0)))
    result$ci <- c(n+f0/d,n+f0*d)
    return(result)
  }
}















































#' Bias-corrected Chao1 species richness estimator
#' 
#' This function implements the bias-corrected Chao1 richness estimate.
#' 
#' 
#' @param data The sample frequency count table for the population of interest.
#' See dataset apples for sample formatting.
#' @param output Logical: whether the results should be printed to screen.
#' @param answers Should the answers be returned as a list?
#' @return The results of the estimator, including standard error.
#' @note The authors of this package strongly discourage the use of this
#' estimator. It is underpinned by totally implausible assumptions that are not
#' made by other richness estimators.  Bias correcting Chao1 is the least of
#' your problems.
#' @author Amy Willis
#' @examples
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' chao1_bc(apples)
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' @export chao1_bc
chao1_bc <- function(data, output=TRUE, answers=FALSE) {
  
  if( !(is.matrix(data) || is.data.frame(data))) {
    filename <- data
    ext <- substr(filename, nchar(filename)-2, nchar(filename))
    if (ext == "csv") {
      data <- read.table(file=filename, header=0,sep=",")
      if( data[1,1] !=1) data <- read.table(filename, header=1,sep=",")
    } else if (ext == "txt") {
      data <- read.table(file=filename, header=0)
    } else cat("Please input your data as a txt or csv file,
               or as an R dataframe or matrix.")
  }
  
  if ( is.factor(data[,1]) ) {
    fs <- as.numeric(as.character(data[,1]))
    data <- cbind(fs,data[,2])
    data <- data[data[,1]!=0,]
  }
  
  
  
  index  <- 1:max(data[,1])
  frequency_index <- rep(0, length(index))
  frequency_index[data[,1]] <- data[,2]
  f1  <- frequency_index[1]
  f2 <- frequency_index[2]
  n <- sum(frequency_index)
  
  f0 <- f1*(f1-1)/(2*(f2+1))
  diversity <- n + f0
  
  diversity_se <- sqrt(f1*(f1-1)/(2*(f2+1)) + f1*(2*f1-1)^2/(4*(f2+1)^2) + f1^2*f2*(f1-1)^2/(4*(f2+1)^4))
  
  if(output) {
    cat("################## Bias-corrected Chao1 ##################\n")
    cat("\tThe estimate of total diversity is", round(diversity),
        "\n \t with std error",round(diversity_se),"\n")
  }
  if(answers) {
    result <- list()
    result$name <- "Chao1_bc"
    result$est <- diversity
    result$seest <- diversity_se
    d <- exp(1.96*sqrt(log(1+result$seest^2/f0)))
    result$ci <- c(n+f0/d,n+f0*d)
    return(result)
  }
}

#' @export chao_shen
chao_shen  <- function(my_data) {
  
  cleaned_data <- check_format(my_data)
  
  if (cleaned_data[1,1]!=1 || cleaned_data[1,2]==0) {
    warning("You don't have an observed singleton count.\n Chao-Shen isn't built for that data structure.\n")
  } 
  
  estimate <- chao_shen_estimate(cleaned_data)  
  cc <- sum(cleaned_data[, 2])
  
  j_max <- length(cleaned_data[, 2])  
  
  derivative <- vector("numeric", j_max)
  for (i in 1:j_max) {
    perturbed_table <- cleaned_data
    perturbed_table[i, 2] <- perturbed_table[i, 2] + 1
    upper <- chao_shen_estimate(perturbed_table)
    perturbed_table[i, 2] <- perturbed_table[i, 2] - 2
    lower <- chao_shen_estimate(perturbed_table)
    derivative[i] <- (upper - lower)/2
  }
  
  variance_estimate <- t(derivative) %*% multinomial_covariance(cleaned_data, cc/estimate) %*% derivative
  
  list("est" = estimate, 
       "se" = c(ifelse(variance_estimate < 0, 0, sqrt(variance_estimate))))
}

chao_shen_estimate <- function(cleaned_data) {
  n <- sum(cleaned_data[, 2] * cleaned_data[, 1])
  f1 <- ifelse(cleaned_data[1,1] == 1, cleaned_data[1,2], 0)
  
  p_hat <- to_proportions(cleaned_data, type="frequency count")
  chat <- 1 - f1/n
  p_tilde <- chat * p_hat
  
  -sum(p_tilde * log(p_tilde) / (1 - (1 - p_tilde)^n))
  
}

multinomial_covariance <- function(my_data, chat) {
  frequencies <- my_data[, 2]
  j_max <- length(frequencies)  
  
  # divide diagonal by 2 so that when we make it symmetric we don't double count
  estimated_covariance <- diag(frequencies*(1 - frequencies / chat) / 2) 
  
  for (i in 1:(j_max-1)) {
    estimated_covariance[i, (i + 1):j_max] <- -frequencies[i]*frequencies[(i + 1):j_max]/chat
  }
  
  estimated_covariance + t(estimated_covariance)
  
}



#' @export good_turing
good_turing  <- function(my_data) {
  
  cleaned_data <- check_format(my_data)
  
  if (cleaned_data[1,1]!=1 || cleaned_data[1,2]==0) {
    warning("You don't have an observed singleton count.\n Chao-Shen isn't built for that data structure.\n")
  } 
  
  cc <- sum(cleaned_data[, 2])
  n <- sum(cleaned_data[, 2] * cleaned_data[, 1])
  f1 <- ifelse(cleaned_data[1,1] == 1, cleaned_data[1,2], 0)
  
  chat <- cc / (1 - f1/n)
  list("est" = chat, 
       "se" = NA)
}
